;;; -*- Gerbil -*-
;;; Gxtest execution and worker helpers.

(import (only-in :std/misc/path path-expand)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 iota partition)
        (only-in "../support/time" monotonic-micros duration-micros)
        (only-in "./gxtest-context"
                 package-root)
        (only-in "./gxtest-discovery"
                 source-isolated-gxtest-file?
                 gxtest-batches)
        (only-in "./gxtest-expression"
                 gxtest-compiled-batch-expression
                 gxtest-source-load-batch-expression
                 gxtest-batch-expression
                 gxtest-batch-label)
        (only-in "./gxtest-report"
                 test-phase-receipt-line
                 display-test-phase-receipt
                 run-test-phase
                 record-gxtest-result
                 display-gxtest-result
                 gxtest-result-file
                 gxtest-result-status
                 gxtest-result-elapsed-micros
                 gxtest-summary-line
                 gxtest-top-line
                 display-gxtest-timing-summary
                 first-failure-status
                 gxtest-runner-mode-label)
        :gerbil/gambit)

(export test-phase-receipt-line
        display-test-phase-receipt
        run-test-phase
        gxtest-compiled-batch-expression
        gxtest-source-load-batch-expression
        gxtest-batch-label
        gxtest-summary-line
        gxtest-top-line
        run-gxtest-parallel-phase
        run-gxtest-serial-phase
        display-gxtest-timing-summary
        display-gxtest-result
        first-failure-status
        gxtest-runner-mode-label)

;; : (-> Integer Integer)
(def (normalized-exit-status status)
  (cond
   ((and (integer? status) (> status 255))
    (quotient status 256))
   ((integer? status) status)
   (else 1)))

;; : (-> (List Path) String GxTestResult)
(def (run-gxtest-batch/process files expression)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (let (output
          (run-process ["gxi" "-e" expression]
                       directory: package-root
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status
                           (normalized-exit-status exit-status)))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/subprocess files)
  (run-gxtest-batch/process files
                             (gxtest-batch-expression files)))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/compiled-subprocess files)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
  (run-gxtest-batch/process files
                             (gxtest-compiled-batch-expression files)))

;; : (-> Mutex)
(def +compiled-gxtest-eval-lock+ (make-mutex 'compiled-gxtest-eval))

;; : (-> (List Path) Boolean)
(def (eval-compiled-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-compiled-batch-expression files)
              read)))))

;; : (-> (List Path) Boolean)
(def (eval-source-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-source-load-batch-expression files)
              read)))))

;; : (-> (-> Boolean) (Values Integer String))
(def (write-gxtest-exception exn port)
  (parameterize ((dump-stack-trace? #f))
    (display-exception exn port)))

;; : (-> (-> Boolean) (Values Integer String))
(def (capture-gxtest-eval thunk)
  (let (status 0)
    (let (output
          (call-with-output-string
            (lambda (port)
              (with-catch
               (lambda (exn)
                 (set! status 1)
                 (write-gxtest-exception exn port)
                 (newline port))
               (lambda ()
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (unless (thunk)
                     (set! status 1))))))))
      (unless (equal? output "")
        (display output)
        (force-output))
      (values status output))))

;; : (-> (List Path) (-> (List Path) Boolean) GxTestResult)
(def (run-gxtest-batch/in-process files eval-thunk)
  (let ((start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (call-with-values
      (lambda ()
        (capture-gxtest-eval
         (lambda ()
           (eval-thunk files))))
      (lambda (status output)
        (list label
              status
              output
              (duration-micros start-micros (monotonic-micros)))))))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/compiled-in-process files)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
  (add-load-path! (path-expand ".gerbil/lib" package-root))
  (run-gxtest-batch/in-process files eval-compiled-gxtest-batch!))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/source-in-process files)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
  (run-gxtest-batch/in-process files eval-source-gxtest-batch!))

;; : (-> Path GxTestResult)
(def (run-gxtest-file/subprocess file)
  (run-gxtest-batch/subprocess [file]))

;; spawn-test-workers
;;   : (-> Integer (-> Void) (List Value))
;;   | doc m%
;;       `spawn-test-workers` owns the runner's worker creation boundary; the
;;       caller controls scheduling and joins every returned thread.
;;
;;       # Examples
;;
;;       ```scheme
;;       (length (spawn-test-workers 0 thunk))
;;       ;; => 0
;;       ```
;;     %
(def (spawn-test-workers count thunk)
  (map (lambda (_) (spawn thunk))
       (iota (max 0 count))))

;; : (-> (List Path) (List GxTestResult))
(def (serial-gxtest-results files)
  (let-values (((isolated-files groupable-files)
                (partition source-isolated-gxtest-file? files)))
    (append
     (if (null? groupable-files)
       []
       [(record-gxtest-result
         (run-gxtest-batch/subprocess groupable-files))])
     (map (lambda (file)
            (record-gxtest-result (run-gxtest-file/subprocess file)))
          isolated-files))))

;; : (-> (List Path) Integer (List GxTestResult))
(def (make-gxtest-work-index-taker count)
  (let ((next-index 0)
        (index-mx (make-mutex 'gxtest-runner-index)))
    (lambda ()
      (with-lock index-mx
        (lambda ()
          (and (< next-index count)
               (let (index next-index)
                 (set! next-index (+ next-index 1))
                 index)))))))

;; : (-> Vector Vector Integer Void)
(def (run-gxtest-worker-item! items results index)
  (vector-set! results
               index
               (record-gxtest-result
                (run-gxtest-batch/subprocess
                 (vector-ref items index)))))

;; : (-> (-> MaybeInteger) Vector Vector Void)
(def (run-gxtest-worker-loop! take-index items results)
  (let loop ()
    (let (index (take-index))
      (when index
        (run-gxtest-worker-item! items results index)
        (loop)))))

;; : (-> (List Path) Integer (List GxTestResult))
(def (parallel-gxtest-results files worker-count)
  (let* ((items (list->vector (gxtest-batches files worker-count)))
         (count (vector-length items))
         (results (make-vector count #f))
         (take-index (make-gxtest-work-index-taker count)))
    (let (threads
          (spawn-test-workers
           worker-count
           (lambda ()
             (run-gxtest-worker-loop! take-index items results))))
      (for-each thread-join! threads)
      (vector->list results))))

;; : (-> (List Path) Boolean GxTestResult)
(def (run-gxtest-in-process-batch files compiled-in-process?)
  (if compiled-in-process?
    (run-gxtest-batch/compiled-in-process files)
    (run-gxtest-batch/source-in-process files)))

;; : (-> (List Path) (List Path) Integer Boolean Boolean (List GxTestResult))
(def (run-gxtest-parallel-phase files parallel-files worker-count
                                source-in-process? compiled-in-process?)
  (if source-in-process?
    (list (record-gxtest-result
           (run-gxtest-in-process-batch files compiled-in-process?)))
    (parallel-gxtest-results parallel-files worker-count)))

;; : (-> (List Path) Boolean (List GxTestResult))
(def (run-gxtest-serial-phase serial-files source-in-process?)
  (if source-in-process?
    []
    (serial-gxtest-results serial-files)))

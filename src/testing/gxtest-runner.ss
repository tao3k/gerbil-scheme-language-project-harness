;;; -*- Gerbil -*-
;;; Gxtest framework runner for package test targets.

(import (only-in :std/misc/path directory-files path-directory path-expand path-strip-directory)
        (only-in :std/misc/process run-process)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-join string-prefix? string-suffix?)
        (only-in "../build-api/package-receipt"
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-line
                 gslph-package-build-receipt-status-ref
                 gslph-package-build-receipt-write)
        (only-in "../build-api/package-spec"
                 gslph-package-api-spec)
        (only-in "../build-api/worker-count"
                 build-worker-count
                 gxtest-worker-count
                 gxtest-worker-count/cores
                 machine-efficiency-core-count
                 machine-logical-core-count
                 machine-performance-core-count
                 sync-build-worker-count!)
        (only-in "../support/time" monotonic-micros duration-micros)
        (only-in "./gxtest-smoke"
                 gslph-default-gxtest-smoke-files)
        (only-in "./gxtest-context"
                 package-root
                 source-root
                 test-root
                 package-name
                 configure-build-root!
                 ensure-build-root!
                 source-output-prefix
                 test-output-prefix
                 module-path-stem
                 gxtest-test-module-path
                 gxtest-source-module-path)
        (only-in "./gxtest-discovery"
                 gxtest-export-symbols
                 gxtest-file-forms
                 gxtest-file-exported-symbols
                 gxtest-file-exported-suite
                 gxtest-file-local-suite?
                 gxtest-files-local-suite?
                 gxtest-file-module-symbol
                 gxtest-selected-source-files
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files
                 parallel-gxtest-files
                 serial-gxtest-files
                 gxtest-batches)
        (only-in "./gxtest-delegate"
                 gxtest-delegate-contract
                 gxtest-delegate-contract-filter
                 gxtest-delegate-contract-receipt
                 gxtest-delegate-contract-supported?
                 gxtest-filtered-files)
        (only-in "./model"
                 testing-receipt-details)
        :gerbil/gambit)
(export clean-target
        compile-spec
        configure-build-root!
        default-gxtest-test-files
        dev-launcher-binpath
        gxtest-test-spec
        gxtest-test-files
        gxtest-batch-label
        gxtest-batches
        gxtest-worker-count/cores
        gxtest-compiled-batch-expression
        gxtest-delegate-contract
        gxtest-delegate-contract-filter
        gxtest-delegate-contract-receipt
        gxtest-delegate-contract-supported?
        gxtest-file-exported-symbols
        gxtest-file-exported-suite
        gxtest-file-local-suite?
        gxtest-file-module-symbol
        gxtest-source-load-batch-expression
        gxtest-selected-test-files
        install-launcher-binpath
        gslph-package-build-receipt-status-ref
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
        parallel-gxtest-files
        serial-gxtest-files
        build-worker-count
        machine-efficiency-core-count
        machine-logical-core-count
        machine-performance-core-count
        compile-package-api-if-stale
        scoped-policy-receipt-path
        scoped-policy-source-files
        sync-build-worker-count!
        test-file-target
        test-full-target
        test-phase-receipt-line
        test-target
        selected-gxtest-build-current?
        selected-gxtest-build-output-files
        selected-gxtest-build-receipt-path
        selected-gxtest-build-receipt-status
        selected-gxtest-build-source-files
        test-runner-worker-count
        write-package-api-build-receipt!)

;; : (-> Path)
(def (package-build-api-path)
  (path-expand "src/build-api/package-build.ss" package-root))

;; : (-> Void)
(def (load-package-build-api!)
  (let (root package-root)
    (load (package-build-api-path))
    (eval `(gslph-package-configure-build-root! ,root))))

;; : (-> Void)
(def (compile-package-api!)
  (load-package-build-api!)
  (eval '(gslph-package-compile-target #f #f #t #f #f)))

;; : (-> (List Path))
(def (gxtest-test-files)
  (top-level-test-files))

;; : (-> (List Path))
(def (default-gxtest-test-files)
  (gslph-default-gxtest-smoke-files))

;; : (-> (List ModulePath))
(def (gxtest-test-spec)
  (map gxtest-test-module-path (gxtest-test-files)))

;; : (-> (List Path) (List ModulePath))
(def (gxtest-files-spec files)
  (map gxtest-test-module-path files))

;; : (-> String Integer String)
(def (test-phase-receipt-line name elapsed-micros)
  (string-append "[gslph-test-phase] name=" name
                 " elapsedMicros=" (number->string elapsed-micros)
                 " elapsedMs=" (number->string (quotient elapsed-micros 1000))
                 "\n"))

;; : (-> String Integer Void)
(def (display-test-phase-receipt name elapsed-micros)
  (display (test-phase-receipt-line name elapsed-micros))
  (force-output))

;; : (-> String (-> Value) Value)
(def (run-test-phase name thunk)
  (let (start-micros (monotonic-micros))
    (let (result (thunk))
      (display-test-phase-receipt
       name
       (duration-micros start-micros (monotonic-micros)))
      result)))

(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "commands/search-workspace-scope-light.ss"
    "commands/search.ss"
    "commands/query.ss"
    "commands/check-cache.ss"
    "commands/check.ss"
    "commands/evidence.ss"
    "commands/agent.ss"
    "commands/guide.ss"
    "commands/info.ss"
    "search-light-launcher.ss"
    "build-api/source-coverage.ss"
    "build-api/package-receipt.ss"
    "policy/gxtest.ss"
    "support/time.ss"
    "benchmark/gate.ss"
    "commands/bench-light.ss"))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (cond
   ((or full? release?)
    (error "full and release compile specs are owned by native-build"))
   (binary? cli-bootstrap-modules)
   (else (gslph-package-api-spec))))

;; : (-> String)
(def (module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; : (-> Path)
(def (package-api-output-root)
  (path-expand (source-output-prefix)
               (path-expand ".gerbil/lib" package-root)))

;; : (-> Path)
(def (package-api-build-receipt-path)
  (path-expand ".gerbil/build/package-api.receipt" package-root))

;; : (-> Path)
(def (selected-gxtest-build-receipt-path)
  (path-expand ".gerbil/build/selected-gxtest.receipt" package-root))

;; : (-> (List Path) String)
(def (scoped-policy-cache-key files)
  (let* ((scope (string-join (sort files string<?) "\n"))
         (limit 4294967296))
    (let loop ((chars (string->list scope))
               (hash 2166136261))
      (if (null? chars)
        (number->string hash 16)
        (loop (cdr chars)
              (modulo (* (bitwise-xor hash (char->integer (car chars)))
                         16777619)
                      limit))))))

;; : (-> [(List Path)] Path)
(def (scoped-policy-receipt-path (files []))
  (path-expand
   (string-append ".gerbil/build/scoped-policy/"
                  (scoped-policy-cache-key files)
                  ".receipt")
   package-root))

;; : (-> (List Path))
(def (package-api-build-source-files)
  (map (lambda (module)
         (path-expand module source-root))
       (gslph-package-api-spec)))

;; : (-> (List Path))
(def (package-api-build-output-files)
  (map (lambda (module)
         (path-expand
          (string-append (module-path-stem module) ".ssi")
          (package-api-output-root)))
       (gslph-package-api-spec)))

;; : (-> (List Path) (List Path))
(def (selected-gxtest-build-source-files files)
  (map (lambda (file)
         (path-expand file package-root))
       (gxtest-selected-source-files files)))

;; : (-> (List Path) (List Path))
(def (selected-gxtest-build-output-files files)
  (map (lambda (file)
         (cond
          ((string-prefix? "src/" file)
           (path-expand
            (string-append
             (module-path-stem (gxtest-source-module-path file))
             ".ssi")
            (path-expand (source-output-prefix)
                         (path-expand ".gerbil/lib" package-root))))
          ((string-prefix? "t/" file)
           (path-expand
            (string-append
             (module-path-stem (gxtest-test-module-path file))
             ".ssi")
            (path-expand (test-output-prefix)
                         (path-expand ".gerbil/lib" package-root))))
          (else
           (error "selected gxtest source file must be under src/ or t/" file))))
       (gxtest-selected-source-files files)))

;; : (-> Path Boolean)
(def (gslph-source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (eq? (file-info-type (file-info path)) 'directory))))

;; : (-> Path Boolean)
(def (gslph-gerbil-source-file? path)
  (string-suffix? ".ss" path))

;; : (-> Path Path (List Path))
(def (scoped-policy-directory-source-files directory prefix)
  (apply append
         (map (lambda (entry)
                (let* ((path (path-expand entry directory))
                       (relative
                        (if (string=? prefix "")
                          entry
                          (string-append prefix "/" entry))))
                  (cond
                   ((member entry '("." "..")) [])
                   ((gslph-source-directory? path)
                    (scoped-policy-directory-source-files path relative))
                   ((gslph-gerbil-source-file? entry) [path])
                   (else []))))
              (sort (directory-files directory) string<?))))

;; : (-> (List Path) (List Path))
(def (scoped-policy-source-files files)
  (sort (append
         (scoped-policy-directory-source-files source-root "")
         (map (lambda (file)
                (path-expand file package-root))
              files))
        string<?))

;; : (-> BuildReceiptStatus)
(def (package-api-build-receipt-status)
  (gslph-package-build-receipt-status
   (package-api-build-receipt-path)
   expected-sources: (package-api-build-source-files)
   expected-outputs: (package-api-build-output-files)))

;; : (-> (List Path) BuildReceiptStatus)
(def (selected-gxtest-build-receipt-status files)
  (gslph-package-build-receipt-status
   (selected-gxtest-build-receipt-path)
   expected-sources: (selected-gxtest-build-source-files files)
   expected-outputs: (selected-gxtest-build-output-files files)))

;; : (-> BuildReceiptStatus Boolean)
(def (package-api-build-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Boolean)
(def (selected-gxtest-build-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Void)
(def (display-package-api-build-receipt-status status)
  (display (gslph-package-build-receipt-status-line status))
  (newline)
  (force-output))

;; : (-> Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> Void)
(def (write-package-api-build-receipt!)
  (let (stamp (package-api-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (package-api-build-source-files)
     (package-api-build-output-files))))

;; : (-> (List Path) Void)
(def (write-selected-gxtest-build-receipt! files)
  (let (stamp (selected-gxtest-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (selected-gxtest-build-source-files files)
     (selected-gxtest-build-output-files files))))

;; : (-> (List Path) Void)
(def (write-scoped-policy-receipt! files)
  (let (stamp (scoped-policy-receipt-path files))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (scoped-policy-source-files files)
     [stamp]
     version: 'gslph-scoped-policy-receipt.v1)))

;; : (-> (List Path) BuildReceiptStatus)
(def (scoped-policy-receipt-status files)
  (let (stamp (scoped-policy-receipt-path files))
    (gslph-package-build-receipt-status
     stamp
     version: 'gslph-scoped-policy-receipt.v1
     expected-sources: (scoped-policy-source-files files)
     expected-outputs: [stamp])))

;; : (-> BuildReceiptStatus Boolean)
(def (scoped-policy-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> (List Path) Void)
(def (run-scoped-policy! files)
  (add-load-path! ".")
  (add-load-path! "src")
  (add-load-path! "t")
  (load "src/policy/gxtest.ss")
  (let* ((policy-report (eval 'policy-report))
         (display-report (eval 'display-project-policy-report))
         (report (policy-report "." files)))
    (when (not (equal? (hash-get report 'status) "pass"))
      (display-report report)
      (exit 1))))

;; : (-> (List Path) Void)
(def (run-scoped-policy-if-stale files)
  (let (status (scoped-policy-receipt-status files))
    (unless (scoped-policy-current? status)
      (run-scoped-policy! files)
      (write-scoped-policy-receipt! files))))

;; : (-> Integer [Maybe (-> Void)] BuildReceiptStatus)
(def (compile-package-api-if-stale worker-count (compile-thunk #f))
  (let (status (package-api-build-receipt-status))
    (display-package-api-build-receipt-status status)
    (if (package-api-build-current? status)
      status
      (begin
        (if compile-thunk
          (compile-thunk)
          (compile-package-api!))
        (write-package-api-build-receipt!)
        (package-api-build-receipt-status)))))

;; : (-> (List Path) Integer Void)
(def (compile-selected-gxtest! files worker-count)
  (load-package-build-api!)
  (eval `(gslph-package-compile-gxtest-target
          ',(gxtest-selected-source-module-files files)
          ',(gxtest-selected-test-files files)
          ,worker-count)))

;; : (-> (List Path) Integer BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files worker-count)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-package-api-build-receipt-status status)
    (if (selected-gxtest-build-current? status)
      status
      (begin
        (compile-selected-gxtest! files worker-count)
        (write-selected-gxtest-build-receipt! files)
        (selected-gxtest-build-receipt-status files)))))

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

;; : (-> Path)
(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

;; : (-> Path)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install asp gerbil-scheme into $HOME/.local/bin")))

;; : (-> Path Void)
(def (delete-file* path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> Path Void)
(def (cleanup-compile-exe-artifacts! binpath)
  (let* ((bindir (path-directory binpath))
         (name (path-strip-directory binpath))
         (prefix (string-append name "__exe")))
    (for-each
     (lambda (suffix)
       (delete-file* (path-expand (string-append prefix suffix) bindir)))
     '(".c" "_.c" ".scm" ".o" "_.o"))))

;; : (-> Void)
(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (delete-file* binpath)
    (cleanup-compile-exe-artifacts! binpath))
  #!void)

;; : (-> Integer Integer)
(def (test-runner-worker-count file-count)
  (gxtest-worker-count file-count))

;; : (-> Datum String)
(def (datum-string value)
  (call-with-output-string
    (lambda (out)
      (write value out))))

;; : (-> Path String)
(def (join-gxtest-args files)
  (string-join (map datum-string files) " "))

(def (join-strings values separator)
  (string-join values separator))

(def (gxtest-compiled-import-clause file)
  (string-append "(only-in "
                 (datum-string (gxtest-file-module-symbol file))
                 " "
                 (datum-string (gxtest-file-exported-suite file))
                 ")"))

(def (gxtest-compiled-run-clause file)
  (string-append " (unless (run-test-suite! "
                 (datum-string (gxtest-file-exported-suite file))
                 ") (set! ok #f))"))

(def (gxtest-compiled-batch-expression files (contract #f))
  (let (files (gxtest-filtered-files files contract))
    (unless (gxtest-delegate-contract-supported? contract files)
      (error "unsupported gxtest delegate contract"
             (testing-receipt-details
              (gxtest-delegate-contract-receipt contract files))))
  (string-append "(begin"
                 " (import :std/test "
                 (join-strings (map gxtest-compiled-import-clause files) " ")
                 ")"
                 " (let (ok #t)"
                 (join-strings (map gxtest-compiled-run-clause files) " ")
                 " ok)"
                 ")")))

(def (gxtest-source-load-clause file)
  (string-append "(load " (datum-string file) ")"))

(def (gxtest-source-load-batch-expression files (contract #f))
  (let (files (gxtest-filtered-files files contract))
    (unless (gxtest-delegate-contract-supported? contract files)
      (error "unsupported gxtest delegate contract"
             (testing-receipt-details
              (gxtest-delegate-contract-receipt contract files))))
  (string-append "(begin"
                 " (add-load-path! \".\")"
                 " (add-load-path! \"src\")"
                 " (add-load-path! \"t\")"
                 " (import :std/test) "
                 (join-strings (map gxtest-source-load-clause files) " ")
                 " (let (ok #t)"
                 (join-strings (map gxtest-compiled-run-clause files) " ")
                 " ok)"
                 ")")))

(def (gxtest-batch-label files)
  (match files
    ([] "empty")
    ([file] file)
    ([file . rest]
     (string-append file ",+" (number->string (length rest))))))

(def (gxtest-batch-expression files)
  (string-append "(begin"
                 " (add-load-path! \".\")"
                 " (add-load-path! \"src\")"
                 " (add-load-path! \"t\")"
                 " (import :gerbil/tools/gxtest)"
                 " (main "
                 (join-gxtest-args files)
                 "))"))

;; : (-> Integer Integer)
(def (normalized-exit-status status)
  (cond
   ((and (integer? status) (> status 255))
    (quotient status 256))
   ((integer? status) status)
   (else 1)))

(def (run-gxtest-batch/subprocess files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (let (output
          (run-process ["gxi" "-e" (gxtest-batch-expression files)]
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

(def (run-gxtest-batch/compiled-subprocess files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
    (let (output
          (run-process ["gxi" "-e" (gxtest-compiled-batch-expression files)]
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

(def +compiled-gxtest-eval-lock+ (make-mutex 'compiled-gxtest-eval))

(def (eval-compiled-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-compiled-batch-expression files)
              read)))))

(def (eval-source-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-source-load-batch-expression files)
              read)))))

(def (run-gxtest-batch/compiled-in-process files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
    (let (output
          (call-with-output-string
            (lambda (port)
              (with-catch
               (lambda (exn)
                 (set! status 1)
                 (display exn port)
                 (newline port))
               (lambda ()
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (unless (eval-compiled-gxtest-batch! files)
                     (set! status 1))))))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

(def (run-gxtest-batch/source-in-process files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
    (let (output
          (call-with-output-string
            (lambda (port)
              (with-catch
               (lambda (exn)
                 (set! status 1)
                 (display exn port)
                 (newline port))
               (lambda ()
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (unless (eval-source-gxtest-batch! files)
                     (set! status 1))))))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

;; : (-> Path GxTestResult)
(def (run-gxtest-file/subprocess file)
  (run-gxtest-batch/subprocess [file]))

;; : (-> GxTestResult Path)
(def (gxtest-result-file result)
  (list-ref result 0))

;; : (-> GxTestResult Integer)
(def (gxtest-result-status result)
  (list-ref result 1))

;; : (-> GxTestResult String)
(def (gxtest-result-output result)
  (list-ref result 2))

;; : (-> GxTestResult Integer)
(def (gxtest-result-elapsed-micros result)
  (list-ref result 3))

;; spawn-test-workers
;;   : (-> Integer (-> Void) (List Thread))
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
  (let loop ((remaining count) (threads []))
    (if (<= remaining 0)
      threads
      (loop (- remaining 1)
            (cons (spawn thunk) threads)))))

;; : (-> (List Path) (List GxTestResult))
(def (serial-gxtest-results files)
  (if (null? files)
    []
    (list (record-gxtest-result (run-gxtest-batch/subprocess files)))))

;; : (-> (List Path) Integer (List GxTestResult))
(def (parallel-gxtest-results files worker-count)
  (let* ((items (list->vector (gxtest-batches files worker-count)))
         (count (vector-length items))
         (results (make-vector count #f))
         (next-index 0)
         (index-mx (make-mutex 'gxtest-runner-index)))
    (def (take-index)
      (with-lock index-mx
        (lambda ()
          (if (< next-index count)
            (let (index next-index)
              (set! next-index (+ next-index 1))
              index)
            #f))))
    (def (worker)
      (let loop ()
        (let (index (take-index))
          (when index
            (vector-set! results
                         index
                         (record-gxtest-result
                          (run-gxtest-batch/subprocess
                           (vector-ref items index))))
            (loop)))))
    (let (threads (spawn-test-workers worker-count worker))
      (for-each thread-join! threads)
      (vector->list results))))

;; : (-> GxTestResult GxTestResult)
(def (record-gxtest-result result)
  (display-test-phase-receipt
   (string-append "run:" (gxtest-result-file result))
   (gxtest-result-elapsed-micros result))
  result)

;; : (-> GxTestResult Void)
(def (display-gxtest-result result)
  (display (gxtest-result-output result)))

;; : (-> (List GxTestResult) Integer)
(def (first-failure-status results)
  (let (failure (find failed-gxtest-result? results))
    (if failure (gxtest-result-status failure) 0)))

(def (failed-gxtest-result? result)
  (not (zero? (gxtest-result-status result))))

(def (gxtest-runner-mode-label source-in-process? compiled-in-process?)
  (cond
   (compiled-in-process? "compiled-in-process")
   (source-in-process? "source-in-process")
   (else "subprocess")))

(def (run-gxtest-in-process-batch files compiled-in-process?)
  (if compiled-in-process?
    (run-gxtest-batch/compiled-in-process files)
    (run-gxtest-batch/source-in-process files)))

(def (run-gxtest-parallel-phase files parallel-files worker-count
                                source-in-process? compiled-in-process?)
  (if source-in-process?
    (list (record-gxtest-result
           (run-gxtest-in-process-batch files compiled-in-process?)))
    (parallel-gxtest-results parallel-files worker-count)))

(def (run-gxtest-serial-phase serial-files source-in-process?)
  (if source-in-process?
    []
    (serial-gxtest-results serial-files)))

;; : (-> (List Path) Void)
(def (run-gxtest-files files)
  (let* ((parallel-files (parallel-gxtest-files files))
         (serial-files (serial-gxtest-files files))
         (worker-count (test-runner-worker-count (length parallel-files)))
         (source-in-process?
          (and (= worker-count 1)
               (gxtest-files-local-suite? files)))
         (selected-status
          (and source-in-process?
               (selected-gxtest-build-receipt-status files)))
         (compiled-in-process?
          (and selected-status
               (selected-gxtest-build-current? selected-status)))
         (parallel-results
          (run-gxtest-parallel-phase files
                                     parallel-files
                                     worker-count
                                     source-in-process?
                                     compiled-in-process?))
         (serial-results
          (run-gxtest-serial-phase serial-files source-in-process?))
         (results (append parallel-results serial-results))
         (status (first-failure-status results)))
    (display (string-append "[gslph-test-runner] files="
                            (number->string (length files))
                            " jobs="
                            (number->string worker-count)
                            " serial="
                            (number->string (length serial-files))
                            " mode="
                            (gxtest-runner-mode-label source-in-process?
                                                       compiled-in-process?)
                            "\n"))
    (force-output)
    (for-each display-gxtest-result results)
    (if (zero? status)
      (begin
        (display "OK\n")
        (force-output))
      (exit status))))

;; : (-> Path Boolean)
(def (explicit-project-policy-test-file? entry)
  (string=? entry "project-policy-test.ss"))

;; : (-> Path Boolean)
(def (top-level-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))
       (not (explicit-project-policy-test-file? entry))))

;; : (-> (List Path))
(def (top-level-test-files)
  (ensure-build-root!)
  (map (lambda (path)
         (string-append "t/" path))
       (filter top-level-test-file?
               (sort (directory-files test-root) string<?))))

;; : (-> (List Path) Void)
(def (run-test-target tests)
  (ensure-build-root!)
  (current-directory package-root)
  (when (null? tests)
    (error "no top-level Gerbil test files found"))
  (sync-build-worker-count!)
  (run-test-phase
   "run-scoped-policy"
   (lambda ()
     (run-scoped-policy-if-stale tests)))
  (run-test-phase
   "run-gxtest"
   (lambda ()
     (run-gxtest-files tests))))

;; : (-> Void)
(def (test-target)
  (run-test-target (default-gxtest-test-files)))

;; : (-> (List Path) Void)
(def (test-file-target files)
  (run-test-target files))

;; : (-> Void)
(def (test-full-target)
  (run-test-target (gxtest-test-files)))

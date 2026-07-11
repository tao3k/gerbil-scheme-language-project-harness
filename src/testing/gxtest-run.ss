;;; -*- Gerbil -*-
;;; Gxtest run-mode orchestration.
;;;
;;; Boundary:
;;; - This module owns runtime mode selection after policy/build receipts are
;;;   current.
;;; - Discovery owns file classification, build owns stale compilation, and
;;;   execution owns subprocess/in-process mechanics.
;;; - Keeping this layer separate prevents the public runner facade from
;;;   mixing test target parsing with performance-sensitive scheduling.

(import (only-in "../build-api/worker-count"
                 gxtest-worker-count)
        (only-in :std/srfi/1 partition any)
        (only-in "../support/time" monotonic-micros duration-micros)
        (only-in "./gxtest-build"
                 compile-selected-gxtest-if-stale)
        (only-in "./gxtest-discovery"
                 compiled-in-process-gxtest-file?
                 gxtest-files-local-suite?
                 parallel-gxtest-files
                 serial-gxtest-files)
        (only-in "./gxtest-execution"
                 run-gxtest-parallel-phase
                 run-gxtest-serial-phase
                 display-gxtest-timing-summary
                 display-gxtest-result
                 first-failure-status
                 gxtest-runner-mode-label)
        (only-in "./gxtest-receipts"
                 selected-gxtest-build-current?)
        (only-in "./memory-profile"
                 gxtest-file-memory-exception?)
        :gerbil/gambit)

(export run-gxtest-files
        test-runner-worker-count)

;; : (-> Integer Integer)
(def (test-runner-worker-count file-count)
  (gxtest-worker-count file-count))

;; split-in-process-gxtest-files
;;   : (-> (List Path) (Values (List Path) (List Path)))
;;   | doc m%
;;       Split a selected in-process batch once into compiled-safe files and
;;       source-only files.  `compiled-in-process-gxtest-file?` reads syntax and
;;       import-closure facts, so runner planning must not re-run it for mode
;;       labels, scheduling, and execution.
;;     %
(def (split-in-process-gxtest-files files)
  (partition compiled-in-process-gxtest-file? files))

;; : (-> (List Path) (List GxTestResult))
(def (run-source-safe-in-process-gxtest-files files)
  (if (null? files)
    []
    (run-gxtest-parallel-phase files files 1 #t #f)))

;; : (-> (List Path) Integer (List GxTestResult))
(def (run-compiled-in-process-gxtest-files files worker-count)
  (if (null? files)
    []
    (let* ((selected-status
            (compile-selected-gxtest-if-stale files worker-count))
           (compiled-in-process?
            (selected-gxtest-build-current? selected-status)))
      (run-gxtest-parallel-phase files
                                 files
                                 worker-count
                                 #t
                                 compiled-in-process?))))

;; : (-> (List Path) (List GxTestResult))
(def (run-source-only-in-process-gxtest-files files)
  (if (null? files)
    []
    (run-gxtest-parallel-phase files files 1 #t #f)))

;; : (-> (List Path) (List GxTestResult))
(def (run-split-source-in-process-gxtest-files source-safe-files
                                               source-only-files)
  (append (run-source-safe-in-process-gxtest-files
           source-safe-files)
          (run-source-only-in-process-gxtest-files
           source-only-files)))

;; : (-> (List Path) Integer (List Path) (List Path) (List GxTestResult))
(def (run-in-process-gxtest-files files
                                  worker-count
                                  source-safe-files
                                  source-only-files)
  (if (pair? source-only-files)
    (run-split-source-in-process-gxtest-files source-safe-files
                                               source-only-files)
    (run-compiled-in-process-gxtest-files files worker-count)))

;; : (-> Boolean Boolean Boolean String)
(def (gxtest-runner-effective-mode source-in-process?
                                   compiled-in-process?
                                   split-source-in-process?)
  (if split-source-in-process?
    "split-source-in-process"
    (gxtest-runner-mode-label source-in-process? compiled-in-process?)))

;; run-gxtest-files
;;   : (-> (List Path) Void)
;;   | doc m%
;;       `run-gxtest-files` owns the run-mode boundary after policy and build
;;       receipts are current.  It keeps local-suite batches in-process for the
;;       warm path, falls back to subprocess execution for isolated or
;;       timing-sensitive files, and emits machine-parseable timing receipts so
;;       performance regressions stay visible to callers.
;;     %
(def (run-gxtest-files files)
  (let* ((parallel-files (parallel-gxtest-files files))
         (serial-files (serial-gxtest-files files))
         (worker-count (test-runner-worker-count (length parallel-files)))
         (source-in-process?
          (and (= worker-count 1)
               (gxtest-files-local-suite? files)
               (not (any gxtest-file-memory-exception? files)))))
    (let-values (((source-safe-files source-only-files)
                  (if source-in-process?
                    (split-in-process-gxtest-files files)
                    (values [] []))))
      (let* ((source-only-in-process? (pair? source-only-files))
             (compiled-in-process?
              (and source-in-process?
                   (not source-only-in-process?)))
             (split-source-in-process?
              (and source-in-process?
                   source-only-in-process?
                   (pair? source-safe-files)))
             (parallel-start-micros (monotonic-micros))
             (parallel-results
              (if source-in-process?
                (run-in-process-gxtest-files files
                                             worker-count
                                             source-safe-files
                                             source-only-files)
                (run-gxtest-parallel-phase files
                                           parallel-files
                                           worker-count
                                           #f
                                           #f)))
             (parallel-wall-micros
              (duration-micros parallel-start-micros (monotonic-micros)))
             (serial-start-micros (monotonic-micros))
             (serial-results
              (run-gxtest-serial-phase serial-files source-in-process?))
             (serial-wall-micros
              (duration-micros serial-start-micros (monotonic-micros)))
             (results (append parallel-results serial-results))
             (status (first-failure-status results)))
        (display (string-append "[gslph-test-runner] files="
                                (number->string (length files))
                                " jobs="
                                (number->string worker-count)
                                " serial="
                                (number->string (length serial-files))
                                " mode="
                                (gxtest-runner-effective-mode
                                 source-in-process?
                                 compiled-in-process?
                                 split-source-in-process?)
                                "\n"))
        (force-output)
        (display-gxtest-timing-summary parallel-results
                                       serial-results
                                       parallel-wall-micros
                                       serial-wall-micros)
        (for-each display-gxtest-result results)
        (if (zero? status)
          (begin
            (display "OK\n")
            (force-output))
          (exit status))))))

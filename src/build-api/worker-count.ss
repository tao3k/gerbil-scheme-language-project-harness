;;; -*- Gerbil -*-
;;; Shared Gerbil build worker configuration.

(import (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-tokenize)
        :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores))
(export build-worker-count
        gxtest-worker-count
        gxtest-worker-count/cores
        machine-efficiency-core-count
        machine-logical-core-count
        machine-performance-core-count
        sync-build-worker-count!)

(def +gerbil-build-cores-env+ "GERBIL_BUILD_CORES")
(def cached-machine-core-topology #f)

;; : (-> String MaybeInteger)
(def (sysctl-integer name)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((output (run-process ["sysctl" "-n" name]
                                 stderr-redirection: #t))
            (tokens (string-tokenize output))
            (value (and (pair? tokens)
                        (string->number (car tokens)))))
       (and (integer? value)
            (> value 0)
            value)))))

;; : (-> Alist)
(def (machine-core-topology)
  (or cached-machine-core-topology
      (let* ((logical (max 1 (##cpu-count)))
             (performance (or (sysctl-integer "hw.perflevel0.logicalcpu")
                              logical))
             (efficiency (or (sysctl-integer "hw.perflevel1.logicalcpu")
                             0)))
        (set! cached-machine-core-topology
          `((logical . ,logical)
            (performance . ,performance)
            (efficiency . ,efficiency)))
        cached-machine-core-topology)))

;; : (-> Alist Symbol Integer)
(def (machine-core-topology-ref topology key default)
  (let (entry (assq key topology))
    (if entry (cdr entry) default)))

;; : (-> Integer)
(def (machine-logical-core-count)
  (machine-core-topology-ref (machine-core-topology) 'logical 1))

;; : (-> Integer)
(def (machine-performance-core-count)
  (machine-core-topology-ref
   (machine-core-topology)
   'performance
   (machine-logical-core-count)))

;; : (-> Integer)
(def (machine-efficiency-core-count)
  (machine-core-topology-ref (machine-core-topology) 'efficiency 0))

;; : (-> Integer)
(def (build-worker-count)
  (let* ((raw (getenv +gerbil-build-cores-env+ #f))
         (configured (and raw (string->number raw))))
    (if (and configured
             (integer? configured)
             (> configured 0))
      configured
      (machine-logical-core-count))))

;; : (-> Integer Integer Integer)
(def (gxtest-worker-count/cores file-count performance-cores)
  (if (<= file-count performance-cores)
    1
    (min (max 1 file-count)
         (max 1 (quotient (+ performance-cores 1) 2)))))

;; : (-> Integer Integer)
(def (gxtest-worker-count file-count)
  (gxtest-worker-count/cores
   file-count
   (machine-performance-core-count)))

;; : (-> Integer)
(def (sync-build-worker-count!)
  (let (worker-count (build-worker-count))
    (set! __available-cores worker-count)
    (setenv +gerbil-build-cores-env+ (number->string worker-count))
    worker-count))

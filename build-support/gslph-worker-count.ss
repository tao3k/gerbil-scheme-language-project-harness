;;; -*- Gerbil -*-
;;; Shared Gerbil build worker configuration.

(import :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores))
(export build-worker-count
        sync-build-worker-count!)

(def +gerbil-build-cores-env+ "GERBIL_BUILD_CORES")

;; : (-> Integer)
(def (build-worker-count)
  (let* ((raw (getenv +gerbil-build-cores-env+ #f))
         (configured (and raw (string->number raw))))
    (if (and configured
             (integer? configured)
             (> configured 0))
      configured
      (max 1 (##cpu-count)))))

;; : (-> Integer)
(def (sync-build-worker-count!)
  (let (worker-count (build-worker-count))
    (set! __available-cores worker-count)
    (setenv +gerbil-build-cores-env+ (number->string worker-count))
    worker-count))

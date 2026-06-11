;;; -*- Gerbil -*-
;;; Checker dispatch over native Gerbil facts.

(import :checker/arity
        :checker/whitelist)

(export run-checker-checks
        run-checker-checks/whitelist)

(def (run-checker-checks index signatures)
  (run-arity-checks index signatures))

(def (run-checker-checks/whitelist index signatures whitelist)
  (append (run-checker-checks index signatures)
          (if (null? whitelist)
            '()
            (run-whitelist-checks index whitelist))))

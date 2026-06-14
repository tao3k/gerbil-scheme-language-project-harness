;;; -*- Gerbil -*-
;;; Checker dispatch over native Gerbil facts.

(import :checker/arity
        :checker/forms
        :checker/types
        :checker/whitelist)

(export run-checker-checks
        run-checker-checks/whitelist)
;; (List TypeFinding) <- ProjectIndex NativeSignatures
(def (run-checker-checks index signatures)
  (append (run-arity-checks index signatures)
          (run-type-mismatch-checks index signatures)
          (run-macro-governance-checks index)))
;; (List TypeFinding) <- ProjectIndex NativeSignatures Whitelist
(def (run-checker-checks/whitelist index signatures whitelist)
  (append (run-checker-checks index signatures)
          (if (null? whitelist)
            '()
            (run-whitelist-checks index whitelist))))

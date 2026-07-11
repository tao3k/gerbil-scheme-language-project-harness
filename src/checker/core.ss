;;; -*- Gerbil -*-
;;; Checker dispatch over native Gerbil facts.

(import :gslph/src/checker/arity
        :gslph/src/checker/forms
        :gslph/src/checker/types
        :gslph/src/checker/whitelist)

(export run-checker-checks
        run-checker-checks/whitelist)
;; : (-> ProjectIndex NativeSignatures (List TypeFinding) )
(def (run-checker-checks index signatures)
  (append (run-arity-checks index signatures)
          (run-type-mismatch-checks index signatures)
          (run-macro-governance-checks index)))
;; : (-> ProjectIndex NativeSignatures Whitelist (List TypeFinding) )
(def (run-checker-checks/whitelist index signatures whitelist)
  (append (run-checker-checks index signatures)
          (if (null? whitelist)
            '()
            (run-whitelist-checks index whitelist))))

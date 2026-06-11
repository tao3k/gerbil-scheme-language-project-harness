;;; -*- Gerbil -*-
;;; Checker dispatch over native Gerbil facts.

(import :checker/arity)

(export run-checker-checks)

(def (run-checker-checks index signatures)
  (run-arity-checks index signatures))

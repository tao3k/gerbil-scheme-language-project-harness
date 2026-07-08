;;; -*- Gerbil -*-
;;; Boundary: eval, environment, and interaction-environment shape.

(import :gerbil/gambit)

(export evaluate-small-expression)

(def (evaluate-small-expression expression)
  (let ((env (interaction-environment)))
    (eval expression env)))

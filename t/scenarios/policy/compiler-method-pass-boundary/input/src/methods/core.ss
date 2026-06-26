;;; -*- Gerbil -*-
;;; Agent-authored method table with anonymous pass lambdas.
(package: sample/methods)
(export run-node-pass)

;; : (-> AST Method Table Lambda Dispatch NodePass)
(def (run-node-pass node)
  node)

(define-type NodePass.
  .begin: (lambda (self stx) (run-node-pass stx))
  .call: (lambda (self stx) (run-node-pass stx))
  .quote: (lambda (self stx) stx))

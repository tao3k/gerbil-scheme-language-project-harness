;;; -*- Gerbil -*-
;;; Boundary:
;;; - Node pass methods are local AST pass handlers.
;;; - The method table remains a dispatch surface, not a lambda sink.
(package: sample/methods)
(import (only-in :std/sugar cut))
(export run-node-pass)

;; run-node-pass
;;   : (-> AST AST)
;;   | type AST = Syntax
;;   | doc m%
;;       `run-node-pass node` dispatches one node through the local pass.
;;     %
(def (run-node-pass node)
  node)

;; node-pass-begin
;;   : (-> NodePass AST AST)
;;   | type NodePass = MethodTable
;;   | type AST = Syntax
;;   | doc m%
;;       `node-pass-begin self stx` owns the begin-node pass branch.
;;     %
(def (node-pass-begin self stx)
  (ast-case stx ()
    ((_ . forms)
     (for-each (cut run-node-pass <>) #'forms)
     stx)))

;; node-pass-call
;;   : (-> NodePass AST AST)
;;   | type NodePass = MethodTable
;;   | type AST = Syntax
;;   | doc m%
;;       `node-pass-call self stx` owns the call-node pass branch.
;;     %
(def (node-pass-call self stx)
  (ast-case stx ()
    ((_ target . operands)
     (for-each (cut run-node-pass <>) #'operands)
     stx)))

;; node-pass-quote
;;   : (-> NodePass AST AST)
;;   | type NodePass = MethodTable
;;   | type AST = Syntax
;;   | doc m%
;;       `node-pass-quote self stx` keeps literal nodes source-preserving.
;;     %
(def (node-pass-quote self stx)
  (ast-case stx ()
    ((_ value)
     stx)))

(define-type NodePass.
  .begin: node-pass-begin
  .call: node-pass-call
  .quote: node-pass-quote)

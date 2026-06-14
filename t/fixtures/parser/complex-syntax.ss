;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/sugar
        (only-in :std/text/json read-json)
        (for-syntax :std/stxutil)
        (rename-in :std/misc/list (foldl fold-left))
        (except-in :std/misc/hash hash-copy)
        (phi: +1 :std/misc/repr)
        (for-template :std/misc/path))
(export make-widget with-widget <Widget> <Renderable> :render)
;; String <- Value SourceLine
(defrule (with-widget value body ...)
  (let ((tmp value))
    body ...))
;; CaptureSafe <- Stx
(defsyntax (capture-safe stx)
  (syntax-case stx ()
    ((_ id expr)
     #'(let ((id expr))
         id))))
;; String
(defclass (<Widget> :object) (name count) transparent: #t)
;; Integer
(defgeneric :render)
;; Integer
(defprotocol <Renderable>)
;; Integer
(defmethod (:render (widget <Widget>))
  (let* ((label "ok")
         (again label)
         (n 1))
    (displayln again)
    (read-json (open-input-string "{}"))
    (:render widget)))
;; String <- String (List String)
(def (make-widget name . rest)
  (let ((count 0))
    (with-widget name
      (make-<Widget> name count))))
;; Dispatch <- Value
(def (dispatch value)
  (match value
    ([? string? s] (make-widget s))
    (else (make-widget "fallback"))))
;; Widget <- Value
(def select
  (case-lambda
    (() (make-widget "empty"))
    ((x) (dispatch x))))

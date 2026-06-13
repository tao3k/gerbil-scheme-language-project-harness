;;; -*- Gerbil -*-
(import :std/sugar
        (only-in :std/text/json read-json)
        (for-syntax :std/stxutil)
        (rename-in :std/misc/list (foldl fold-left))
        (except-in :std/misc/hash hash-copy))
(export make-widget with-widget <Widget> <Renderable> :render)

(defrule (with-widget value body ...)
  (let ((tmp value))
    body ...))

(defsyntax (capture-safe stx)
  (syntax-case stx ()
    ((_ id expr)
     #'(let ((id expr))
         id))))

(defclass (<Widget> :object) (name count) transparent: #t)

(defgeneric :render)

(defprotocol <Renderable>)

(defmethod (:render (widget <Widget>))
  (let* ((label "ok")
         (again label)
         (n 1))
    (displayln again)
    (read-json (open-input-string "{}"))
    (:render widget)))

(def (make-widget name . rest)
  (let ((count 0))
    (with-widget name
      (make-<Widget> name count))))

(def (dispatch value)
  (match value
    ([? string? s] (make-widget s))
    (else (make-widget "fallback"))))

(def select
  (case-lambda
    (() (make-widget "empty"))
    ((x) (dispatch x))))

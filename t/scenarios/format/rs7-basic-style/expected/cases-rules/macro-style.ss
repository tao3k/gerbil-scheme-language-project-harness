;;; -*- Gerbil -*-
;;; Boundary: macro-style forms keep syntax bodies untouched.

(import :gerbil/gambit
        :std/sugar)

(export with-policy-context
        define-rule)

(defsyntax (with-policy-context stx)
  (syntax-case stx ()
    ((_ ctx body ...)
     #'(let ((__ctx ctx))
         body ...))))

(defsyntax (define-rule stx)
  (syntax-case stx ()
    ((_ name (arg ...) body ...)
     #'(def (name arg ...)
         body ...))))

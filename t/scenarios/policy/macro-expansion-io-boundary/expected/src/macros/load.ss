;;; -*- Gerbil -*-
(package: sample/macros)

(export define-fragment)

(defsyntax (define-fragment stx)
  (syntax-case stx ()
    ((_ binding form ...)
     (syntax
      (def binding
        (begin form ...))))))

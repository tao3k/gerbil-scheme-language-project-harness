;;; -*- Gerbil -*-
(package: sample/macros)

(defsyntax (with-order-field stx)
  (def (bad form)
    (raise-syntax-error 'with-order-field "expected (with-order-field order body ...)" form))
  (syntax-case stx ()
    ((_ order body ...)
     #'(let ((current-order order)) body ...))
    (_ (bad stx))))


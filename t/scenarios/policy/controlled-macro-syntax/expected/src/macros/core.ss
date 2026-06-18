;;; -*- Gerbil -*-
;;; Boundary:
;;; - Syntax owners stay thin hygienic wrappers over runtime helpers.
(package: sample/macros)

;;; Boundary:
;;; - with-order-field validates the syntax shape before expansion.
;; with-order-field
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `with-order-field` expands a checked order binding form.
;;
;;       # Examples
;;
;;       ```scheme
;;       (with-order-field order body)
;;       ;; => expanded-syntax
;;       ```
;;     %
(defsyntax (with-order-field stx)
  (syntax-case stx ()
    ((_ order body)
     (with-syntax ((current #'order))
       #'(let ((current-order current)) body)))))

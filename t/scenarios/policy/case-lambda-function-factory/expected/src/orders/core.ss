;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders core owns arity-specialized string decorator factories.
(package: sample/orders)
(export decorate)

;;; Boundary:
;;; - `case-lambda` makes the real arity variants explicit instead of stacking
;;;   wrapper lambdas in one branch.
;; decorate
;;   : (-> String String (-> String String))
;;   | type Decorator = (-> String String)
;;   | doc m%
;;       `decorate prefix` wraps text with `prefix`.
;;       `decorate prefix suffix` wraps text with both sides.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((decorate "<" ">") "paid")
;;       ;; => "<[paid]>"
;;       ```
;;     %
(def decorate
  (case-lambda
    ((prefix)
     (lambda (text)
       (string-append prefix "[" text "]")))
    ((prefix suffix)
     (lambda (text)
       (string-append prefix "[" text "]" suffix)))))

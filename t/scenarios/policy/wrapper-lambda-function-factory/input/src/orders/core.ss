;;; -*- Gerbil -*-
;;; Orders formatter.
(package: sample/orders)
(export decorate-order)

;; decorate-order
;;   : (-> String String (-> String String))
;;   | doc m%
;;       `decorate-order` builds a reusable line decorator.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((decorate-order "<" ">") "A-1")
;;       ;; => "<[A-1]>"
;;       ```
;;     %
(def (decorate-order prefix suffix)
  (let ((left (lambda (text) (string-append prefix text)))
        (right (lambda (text) (string-append text suffix)))
        (normalize (lambda (text) (string-append "[" text "]"))))
    (lambda (text)
      (right (normalize (left text))))))

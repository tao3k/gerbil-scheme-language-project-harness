;;; -*- Gerbil -*-
;;; Boundary:
;;; - Order decoration keeps each specialization behind a named helper so
;;;   repeated wrapper lambdas do not hide the reusable factory shape.
(package: sample/orders)
(export decorate-order)

;; order-prefixer
;;   : (-> String (-> String String))
;;   | doc m%
;;       `order-prefixer` specializes a prefix transform.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((order-prefixer "<") "A-1")
;;       ;; => "<A-1"
;;       ```
;;     %
(def (order-prefixer prefix)
  (lambda (text) (string-append prefix text)))

;; order-suffixer
;;   : (-> String (-> String String))
;;   | doc m%
;;       `order-suffixer` specializes a suffix transform.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((order-suffixer ">") "A-1")
;;       ;; => "A-1>"
;;       ```
;;     %
(def (order-suffixer suffix)
  (lambda (text) (string-append text suffix)))

;; order-normalize
;;   : (-> String String)
;;   | doc m%
;;       `order-normalize` names the reusable line normalization boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-normalize "A-1")
;;       ;; => "[A-1]"
;;       ```
;;     %
(def (order-normalize text)
  (string-append "[" text "]"))

;; decorate-order
;;   : (-> String String (-> String String))
;;   | doc m%
;;       `decorate-order` composes named specializers into one reusable
;;       decorator factory.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((decorate-order "<" ">") "A-1")
;;       ;; => "<[A-1]>"
;;       ```
;;     %
(def (decorate-order prefix suffix)
  (let ((left (order-prefixer prefix))
        (right (order-suffixer suffix)))
    (lambda (text)
      (right (order-normalize (left text))))))

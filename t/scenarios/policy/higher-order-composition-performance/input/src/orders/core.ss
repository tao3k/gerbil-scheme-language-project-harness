;;; -*- Gerbil -*-
;;; Orders facade intent.
(package: sample/orders)
(export decorate)

;; : (-> String String (-> String String))
(def (decorate prefix suffix)
  (let ((left (lambda (text) (string-append prefix text)))
        (right (lambda (text) (string-append text suffix))))
    (lambda (text) (right (left text)))))

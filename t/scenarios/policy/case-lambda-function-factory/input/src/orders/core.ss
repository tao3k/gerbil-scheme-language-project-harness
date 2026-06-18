;;; -*- Gerbil -*-
(package: sample/orders)
(export decorate)

;; : (-> String String (-> String String))
(def (decorate prefix suffix)
  (let ((left (lambda (text) (string-append prefix text)))
        (middle (lambda (text) (string-append "[" text "]")))
        (right (lambda (text) (string-append text suffix))))
    (lambda (text) (right (middle (left text))))))

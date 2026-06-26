;;; -*- Gerbil -*-
;;; Orders facade.
(package: sample/orders)
(export render-active-orders)

;; : (-> (List Order) Map Filter Fold (List String))
(def (render-active-orders orders)
  (let loop ((remaining orders) (out '()))
    (if (null? remaining)
      (reverse out)
      (let* ((order (car remaining))
             (status (cdr (assq 'status order)))
             (id (cdr (assq 'id order))))
        (if (equal? status "active")
          (loop (cdr remaining)
                (cons (string-append id ":" status) out))
          (loop (cdr remaining) out))))))

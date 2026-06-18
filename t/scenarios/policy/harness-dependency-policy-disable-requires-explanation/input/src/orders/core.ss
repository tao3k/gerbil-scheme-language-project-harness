;;; -*- Gerbil -*-
(package: sample/orders)
(export order-total order-totals)

(def (order-total order)
  (hash-get order 'total 0))

(def (order-totals orders)
  (let loop ((rest orders) (out '()))
    (if (null? rest)
      (reverse out)
      (loop (cdr rest)
            (cons (order-total (car rest)) out)))))

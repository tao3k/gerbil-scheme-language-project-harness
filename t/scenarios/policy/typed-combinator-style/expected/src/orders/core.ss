;;; -*- Gerbil -*-
(package: sample/orders)
(export order-total order-totals)

;; Money <- Order
(def (order-total order)
  (hash-get order 'total 0))

;; (List Money) <- (List Order)
(def (order-totals orders)
  (map order-total orders))

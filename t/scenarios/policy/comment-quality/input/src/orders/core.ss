;;; -*- Gerbil -*-
(package: sample/orders)
(export order-total order-totals)

;; : (-> Order Money )
(def (order-total order)
  (hash-get order 'total 0))

;; : (-> (List Order) (List Money) )
(def (order-totals orders)
  (map order-total orders))

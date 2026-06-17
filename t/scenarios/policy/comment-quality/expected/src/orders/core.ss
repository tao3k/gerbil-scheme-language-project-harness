;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders core owns pure order transformation helpers.
(package: sample/orders)
(export order-total order-totals)

;; Money <- Order
(def (order-total order)
  (hash-get order 'total 0))

;;; Boundary:
;;; - order-totals keeps traversal as a pure sequence map.
;;; - The named mapper keeps order-total behavior visible to parser evidence.
;; (List Money) <- (List Order)
(def (order-totals orders)
  (map order-total orders))

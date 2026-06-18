;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders core owns pure order transformation helpers.
(package: sample/orders)
(export order-total order-totals)

;;; Boundary:
;;; - order-total keeps the hash field projection isolated from traversal code.
;; order-total
;;   : (-> Order Money)
;;   | type Money = Number
;;   | doc m%
;;       `order-total order` returns the numeric total stored in `order`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-total (hash (total 12)))
;;       ;; => 12
;;       ```
;;     %
(def (order-total order)
  (hash-get order 'total 0))

;;; Boundary:
;;; - order-totals keeps traversal as a pure sequence map.
;;; - The named mapper keeps order-total behavior visible to parser evidence.
;; order-totals
;;   : (-> (List Order) (List Money))
;;   | type Money = Number
;;   | doc m%
;;       `order-totals orders` maps each order to its numeric total.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-totals (list (hash (total 12)) (hash (total 4))))
;;       ;; => (12 4)
;;       ```
;;     %
(def (order-totals orders)
  (map order-total orders))

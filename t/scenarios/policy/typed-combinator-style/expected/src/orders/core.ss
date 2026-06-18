;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders core owns pure order transformation helpers.
(package: sample/orders)
(import (only-in :clan/base !> compose curry rcurry fun lambda-match λ))
(export order-total order-total/fee order-total/refund classify-order order-totals)

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
;;; - order-total/fee specializes the fee transform through curry.
;; order-total/fee
;;   : (-> Money Order Money)
;;   | type Money = Number
;;   | doc m%
;;       `order-total/fee fee order` adds `fee` to the order total.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-total/fee 3 (hash (total 12)))
;;       ;; => 15
;;       ```
;;     %
(def (order-total/fee fee order)
  (!> order order-total (curry + fee)))

;;; Boundary:
;;; - order-total/refund keeps rcurry visible as a first-class specialization.
;; order-total/refund
;;   : (-> Money Order Money)
;;   | type Money = Number
;;   | doc m%
;;       `order-total/refund amount order` subtracts a refund from the total.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-total/refund 2 (hash (total 12)))
;;       ;; => 10
;;       ```
;;     %
(def (order-total/refund amount order)
  ((rcurry - amount) (order-total order)))

;;; Boundary:
;;; - classify-order keeps local destructuring in a Gerbil-native named lambda.
;; classify-order
;;   : (-> Order Symbol)
;;   | type Order = HashTable
;;   | doc m%
;;       `classify-order order` returns a compact status symbol.
;;
;;       # Examples
;;
;;       ```scheme
;;       (classify-order (hash (state "paid")))
;;       ;; => 'paid
;;       ```
;;     %
(def classify-order
  (fun (classify order)
    ((lambda-match
       ((hash ('state "paid")) 'paid)
       ((hash ('state "cancelled")) 'cancelled)
       (_ 'open))
     order)))

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
  (map (compose (λ (amount) amount) order-total) orders))

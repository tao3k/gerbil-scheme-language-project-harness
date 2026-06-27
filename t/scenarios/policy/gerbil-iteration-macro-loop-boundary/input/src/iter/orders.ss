;;; -*- Gerbil -*-
;;; Input: staged list transforms allocate intermediate lists in a loop.
(package: scenario/gerbil-iteration-macro-loop-boundary/input)
(export active-order-ids)

(def (active-order-ids orders)
  (map (lambda (order) (cdr (assq 'id order)))
       (filter (lambda (order) (cdr (assq 'active? order)))
               orders)))

;;; -*- Gerbil -*-
;;; Input: hot enrichment passes an unknown callback through every row.
(package: scenario/known-procedure-call-fast-path/input)
(export enrich-orders)

(def (order-total order)
  (cdr (assq 'total order)))

(def (enrich-orders orders adjust)
  (map (lambda (order)
         (cons (cons 'adjusted (adjust (order-total order)))
               order))
       orders))

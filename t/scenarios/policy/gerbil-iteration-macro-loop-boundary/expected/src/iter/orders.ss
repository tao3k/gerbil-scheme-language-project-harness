;;; -*- Gerbil -*-
;;; Expected: use a single explicit iteration boundary for filtered projection.
(package: scenario/gerbil-iteration-macro-loop-boundary/expected)
(export active-order-ids)

(def (active-order-ids orders)
  (let loop ((rest orders)
             (ids '()))
    (if (null? rest)
      (reverse ids)
      (let (order (car rest))
        (if (cdr (assq 'active? order))
          (loop (cdr rest)
                (cons (cdr (assq 'id order)) ids))
          (loop (cdr rest) ids))))))

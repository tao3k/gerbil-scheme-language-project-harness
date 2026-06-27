;;; -*- Gerbil -*-
;;; Expected: keep the hot call target lexical and collect in one pass.
(package: scenario/known-procedure-call-fast-path/expected)
(export enrich-orders adjust-total)

(def (order-total order)
  (cdr (assq 'total order)))

(def (adjust-total total)
  (+ total 1))

(def (enrich-orders orders)
  (let loop ((rest orders)
             (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((order (car rest))
             (adjusted (adjust-total (order-total order))))
        (loop (cdr rest)
              (cons (cons (cons 'adjusted adjusted) order)
                    out))))))

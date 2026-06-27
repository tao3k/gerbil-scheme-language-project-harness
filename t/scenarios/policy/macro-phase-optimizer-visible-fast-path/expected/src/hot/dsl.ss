;;; -*- Gerbil -*-
;;; Expected: the macro surface stays thin and generated calls stay lexical.
(package: scenario/macro-phase-optimizer-visible-fast-path/expected)
(export define-adjuster enrich-orders adjust-total)

(def (order-total order)
  (cdr (assq 'total order)))

(def (adjust-total total)
  (+ total 1))

(defrules define-adjuster ()
  ((_ id selector adjuster)
   (def (id rows)
     (let loop ((rest rows)
                (out '()))
       (if (null? rest)
         (reverse out)
         (let* ((row (car rest))
                (adjusted (adjuster (selector row))))
           (loop (cdr rest)
                 (cons (cons (cons 'adjusted adjusted) row)
                       out))))))))

(define-adjuster enrich-orders order-total adjust-total)

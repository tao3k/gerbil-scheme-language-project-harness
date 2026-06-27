;;; -*- Gerbil -*-
;;; Input: the macro DSL generates a hot helper that hides a known call.
(package: scenario/macro-phase-optimizer-visible-fast-path/input)
(export define-adjuster enrich-orders)

(def primitive-table
  (list (cons 'adjust (lambda (total) (+ total 1)))))

(def (primitive name)
  (cdr (assq name primitive-table)))

(def (order-total order)
  (cdr (assq 'total order)))

(defrules define-adjuster ()
  ((_ id selector primitive-name)
   (def (id rows)
     (let ((adjust (primitive 'primitive-name)))
       (let loop ((rest rows)
                  (out '()))
         (if (null? rest)
           (reverse out)
           (let* ((row (car rest))
                  (adjusted (apply adjust (list (selector row)))))
             (loop (cdr rest)
                   (cons (cons (cons 'adjusted adjusted) row)
                         out)))))))))

(define-adjuster enrich-orders order-total adjust)

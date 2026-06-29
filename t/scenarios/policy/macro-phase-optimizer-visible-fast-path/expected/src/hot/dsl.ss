;;; -*- Gerbil -*-
;;; Expected: the macro surface stays thin and generated calls stay lexical.
(package: scenario/macro-phase-optimizer-visible-fast-path/expected)
(export define-adjuster enrich-orders adjust-total)

;; order-total
;;   : (-> Order Number)
;;   | type Order = Alist
;;   | doc m%
;;       `order-total order` isolates the selector used by the generated hot
;;       path so macro expansion does not hide the runtime access boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-total '((total . 3)))
;;       ;; => 3
;;       ```
;;     %
(def (order-total order)
  (cdr (assq 'total order)))

;; adjust-total
;;   : (-> Number Number)
;;   | doc m%
;;       `adjust-total total` is a direct lexical adjuster target for generated
;;       runtime loops.
;;
;;       # Examples
;;
;;       ```scheme
;;       (adjust-total 3)
;;       ;; => 4
;;       ```
;;     %
(def (adjust-total total)
  (+ total 1))

;; define-adjuster
;;   : (-> Identifier Procedure Procedure Syntax)
;;   | warning generated runtime code calls selector and adjuster directly
;;   | doc m%
;;       `define-adjuster` keeps the macro surface thin and emits a runtime
;;       helper whose lexical calls remain visible to optimizer metadata.
;;
;;       # Examples
;;
;;       ```scheme
;;       (define-adjuster enrich-orders order-total adjust-total)
;;       ;; => enrich-orders
;;       ```
;;     %
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

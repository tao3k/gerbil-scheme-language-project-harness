;;; -*- Gerbil -*-
;;; Boundary:
;;; - Order rendering keeps selection and projection in one list combinator
;;;   boundary instead of hand-written traversal scaffolding.
(package: sample/orders)
(import (only-in :std/sugar filter-map))
(export render-active-orders)

;; active-order-line
;;   : (-> Order (Maybe String))
;;   | doc m%
;;       `active-order-line` selects active orders and projects them into the
;;       public render line.
;;
;;       # Examples
;;
;;       ```scheme
;;       (active-order-line '((id . "A-1") (status . "active")))
;;       ;; => "A-1:active"
;;       ```
;;     %
(def (active-order-line order)
  (let ((status (cdr (assq 'status order)))
        (id (cdr (assq 'id order))))
    (and (equal? status "active")
         (string-append id ":" status))))

;; render-active-orders
;;   : (-> (List Order) (List String))
;;   | doc m%
;;       `render-active-orders` keeps list traversal in the `filter-map`
;;       boundary and leaves row selection to `active-order-line`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (render-active-orders orders)
;;       ;; => ("A-1:active")
;;       ```
;;     %
(def (render-active-orders orders)
  (filter-map active-order-line orders))

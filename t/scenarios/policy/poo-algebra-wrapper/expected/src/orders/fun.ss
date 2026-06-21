;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/fun)
(export OrderFunctor. OrderWrapper. map-order wrap-order unwrap-order bind-order)

;; map-order
;;   : (forall (a b) (-> (-> a b) (List a) (List b)))
;;   | doc m%
;;       `map-order f values` maps order values with `f`.
;;     %
(def (map-order f values)
  (map f values))

;; wrap-order
;;   : (forall (a) (-> a (OrderBox a)))
;;   | doc m%
;;       `wrap-order value` wraps `value` in a local order box.
;;     %
(def (wrap-order value)
  (list 'order value))

;; unwrap-order
;;   : (forall (a) (-> (OrderBox a) a))
;;   | doc m%
;;       `unwrap-order box` returns the boxed value.
;;     %
(def (unwrap-order box)
  (cadr box))

;; bind-order
;;   : (forall (a b) (-> (OrderBox a) (-> a (OrderBox b)) (OrderBox b)))
;;   | doc m%
;;       `bind-order box f` applies `f` to the boxed value.
;;     %
(def (bind-order box f)
  (f (unwrap-order box)))

(define-type (OrderFunctor. @ Functor.)
  .map: map-order
  .tap: order-tap
  .ap: order-ap)

(define-type (OrderWrapper. @ Wrapper.)
  .wrap: wrap-order
  .unwrap: unwrap-order
  .bind: bind-order
  .map/wrap: map-order)

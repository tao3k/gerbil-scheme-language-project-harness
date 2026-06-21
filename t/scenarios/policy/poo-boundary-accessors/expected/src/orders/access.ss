;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/brace)
(export order-id order-total order-meta build-order-id new-order-id)

;; order-id
;;   : (-> Order Id)
;;   | doc m%
;;       `order-id order` reads one boundary slot.
;;     %
(def (order-id order)
  (.ref order 'id))

;; order-total
;;   : (-> Order Number)
;;   | doc m%
;;       `order-total order` reads one boundary slot through method syntax.
;;     %
(def (order-total order)
  (.@ order 'total))

;; order-meta
;;   : (-> Order Meta)
;;   | doc m%
;;       `order-meta order` reads diagnostic metadata.
;;     %
(def (order-meta order)
  (.get order 'meta))

;; build-order-id
;;   : (-> Order Id)
;;   | doc m%
;;       `build-order-id order` intentionally has a build prefix but one read.
;;     %
(def (build-order-id order)
  (.ref order 'id))

;; new-order-id
;;   : (-> Order Id)
;;   | doc m%
;;       `new-order-id order` intentionally has a new prefix but one read.
;;     %
(def (new-order-id order)
  (.@ order 'id))

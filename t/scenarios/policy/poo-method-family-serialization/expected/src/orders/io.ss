;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/io)
(export OrderCodec. order-json)

;; order-json
;;   : (-> Order Json)
;;   | doc m%
;;       `order-json order` stays as the domain-specific json projection.
;;     %
(def (order-json order)
  (hash (id (.ref order 'id))
        (total (.ref order 'total))))

(define-type (OrderCodec. @ Wrapper.)
  .wrap: identity
  .unwrap: identity
  .json<-: order-json
  .string<-json: methods.string<-json
  .bytes<-marshal: methods.bytes<-marshal)

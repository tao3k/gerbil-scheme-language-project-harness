;;; -*- Gerbil -*-
(package: sample/orders)
(import
  (only-in :clan/pure/dict/orderdict
           orderdict-empty? orderdict-ref orderdict-put orderdict->list
           list->orderdict orderdict=?)
  (only-in :clan/poo/mop define-type Any raise-type-error)
  (only-in ./table methods.table))
(define-type (OrderDict. @ [methods.table] Value)
  Key: String
  Value: Any
  .empty: orderdict-empty?
  .ref: orderdict-ref
  .acons: (lambda (k v d) (orderdict-put d k v)))


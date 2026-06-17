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
  .validate: => (lambda (super) (lambda (x) (super x)))
  .empty: orderdict-empty?
  .ref: orderdict-ref
  .acons: (lambda (k v d) (orderdict-put d k v))
  .foldl: (lambda (f seed d) seed)
  .<-list: list->orderdict
  .list<-: orderdict->list
  .sexp<-: (lambda (x) `(list->orderdict ,(orderdict->list x)))
  .=?: (lambda (a b) (orderdict=? a b)))


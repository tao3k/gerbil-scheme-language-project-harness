;;; -*- Gerbil -*-
(package: sample/poo-rationaldict-adapter)
(import
  (only-in :clan/pure/dict/rationaldict
           rationaldict-keys rationaldict-min-key rationaldict-max-key
           rationaldict-empty? empty-rationaldict
           rationaldict-put rationaldict-ref rationaldict-has-key? rationaldict-remove
           list->rationaldict rationaldict->list
           rationaldict? rationaldict=?)
  (only-in :clan/poo/mop define-type Any raise-type-error)
  (only-in ./type Rational Unit)
  (only-in ./table Set<-Table. methods.table))

(define-type (RationalDict. @ [methods.table] Value)
  Key: Rational
  Value: Any
  .validate: => (lambda (super)
                  (lambda (x)
                    (unless (rationaldict? x)
                      (raise-type-error "not rationaldict" x))
                    (super x)))
  .empty: empty-rationaldict
  .empty?: rationaldict-empty?
  .ref: rationaldict-ref
  .key?: rationaldict-has-key?
  .acons: (lambda (k v d) (rationaldict-put d k v))
  .remove: rationaldict-remove
  .foldl: rationaldict-foldl
  .foldr: rationaldict-foldr
  .<-list: list->rationaldict
  .list<-: rationaldict->list
  .sexp<-: (lambda (x) `(list->rationaldict ,(rationaldict->list x)))
  .=?: (lambda (d1 d2) (rationaldict=? d1 d2)))

(define-type (RationalSet @ [Set<-Table.])
  Elt: Rational
  Table: {(:: @T RationalDict.) Key: Elt Value: Unit}
  .list<-: rationaldict-keys
  .min-elt: rationaldict-min-key
  .max-elt: rationaldict-max-key)

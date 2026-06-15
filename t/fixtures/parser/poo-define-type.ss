;;; -*- Gerbil -*-
(package: sample/poo-define-type)

(define-type (RationalDict. @ [methods.table] Value)
  Key: Rational
  Value: Any
  slots: =>.+ {value: {type: Value}}
  .validate: validate-value
  .sexp<-: dict->sexp)

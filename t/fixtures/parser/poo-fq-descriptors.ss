;;; -*- Gerbil -*-
(package: sample/poo-fq-descriptors)
(import :clan/poo/mop :clan/poo/brace)

;; FieldDescriptor <- Exponentiation Multiplication
(define-type (F_q. @ [expt<-mul-inv.] .expt .mul-expt)
  .q: (expt .p .n)
  .p: undefined
  .n: undefined
  .xn: undefined
  .Z/pZ: (Z/ .p)
  .x: (.<-n .p)
  .element?: (lambda (x) (vector? x))
  .new: (lambda () (make-vector .n 0))
  .zero: (.new)
  .one: (let (I (.new)) I)
  .add: add-field-elements
  .mul: multiply-field-elements
  .inv: invert-field-element
  .n<-: pack-field-element
  .<-n: unpack-field-element)

;; BinaryFieldFamily <- FieldDescriptor Integer Polynomial Exponentiation Multiplication
(define-type (F_2^n. @ [F_q.] .n .xn .expt .mul-expt)
  .p: 2
  .element?: exact-integer?
  .zero: 0
  .one: 1
  .add: bitwise-xor
  .sub: bitwise-xor
  .neg: identity
  .=?: =
  .mul: multiply-binary-field
  .n<-: identity
  .<-n: identity)

;; ByteField <- BinaryFieldFamily
(define-type (F_2^8 @ [F_2^n.])
  .n: 8
  .xn: 27)

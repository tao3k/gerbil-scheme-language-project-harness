;;; -*- Gerbil -*-
;;; Boundary: define-values, define-syntax, syntax-error source shape.

(define-library (fixture rs7 basic macro-values)
  (export left right use-syntax-error)
  (import (scheme base))
  (begin
    (define-values (left right)
      (values 'left 'right))
    (define-syntax use-syntax-error
      (syntax-rules ()
        ((_ message)
         (syntax-error "fixture syntax error" message))))))

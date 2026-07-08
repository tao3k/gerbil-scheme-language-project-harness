;;; -*- Gerbil -*-
;;; Boundary: case-lambda library declaration and variadic clauses.

(define-library (fixture rs7 basic case-lambda-complete)
  (export arity-render)
  (import (scheme base)
          (scheme case-lambda))
  (begin
    (define arity-render
      (case-lambda
        (()
         'none)
        ((one)
         ['one one])
        ((one two . rest)
         ['many one two rest])))))

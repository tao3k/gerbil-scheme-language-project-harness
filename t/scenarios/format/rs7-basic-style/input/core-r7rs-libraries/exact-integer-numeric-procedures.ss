;;; -*- Gerbil -*-    
;;; Boundary: exact integer, division, rational, and quotient variants.    

(define-library (fixture rs7 basic exact-integers)
  (export exact-integer-sample)
  (import (scheme base))
  (begin
    (define (exact-integer-sample x y)
      (list (exact-integer? x)
            (zero? x)
            (positive? x)
            (negative? x)
            (odd? x)
            (even? x)
            (floor/ x y)
            (floor-quotient x y)
            (floor-remainder x y)
            (truncate/ x y)
            (truncate-quotient x y)
            (truncate-remainder x y)
            (numerator x)
            (denominator x)
            (rationalize x y)
            (square x)
            (exact-integer-sqrt x)))))    


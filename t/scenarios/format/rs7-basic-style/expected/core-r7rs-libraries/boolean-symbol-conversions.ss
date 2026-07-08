;;; -*- Gerbil -*-
;;; Boundary: boolean, symbol, number/string conversion procedures.

(define-library (fixture rs7 basic conversions)
  (export conversion-sample)
  (import (scheme base))
  (begin
    (define (conversion-sample value)
      (list (boolean=? #t (not #f))
            (symbol=? 'alpha 'alpha)
            (symbol->string 'alpha)
            (string->symbol "alpha")
            (number->string value)
            (number->string value 16)
            (string->number "42")
            (string->number "2a" 16)
            (exact value)
            (inexact value)))))

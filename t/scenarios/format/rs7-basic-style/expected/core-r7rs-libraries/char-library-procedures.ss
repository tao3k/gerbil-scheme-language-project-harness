;;; -*- Gerbil -*-
;;; Boundary: character library predicates, comparisons, and case conversion.

(define-library (fixture rs7 basic char)
  (export char-sample)
  (import (scheme base)
          (scheme char))
  (begin
    (define (char-sample ch)
      (list (char-alphabetic? ch)
            (char-numeric? ch)
            (char-whitespace? ch)
            (char-upper-case? ch)
            (char-lower-case? ch)
            (char-ci=? ch #\a)
            (char-ci<? ch #\z)
            (char-ci>? ch #\a)
            (char-ci<=? ch #\z)
            (char-ci>=? ch #\a)
            (char-upcase ch)
            (char-downcase ch)
            (char-foldcase ch)
            (digit-value ch)))))

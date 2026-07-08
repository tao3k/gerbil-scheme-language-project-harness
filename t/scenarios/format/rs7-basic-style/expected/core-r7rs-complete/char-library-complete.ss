;;; -*- Gerbil -*-
;;; Boundary: char library string case conversion variants.

(define-library (fixture rs7 basic char-complete)
  (export char-complete-sample)
  (import (scheme base)
          (scheme char))
  (begin
    (define (char-complete-sample text)
      (list (string-upcase text)
            (string-downcase text)
            (string-foldcase text)
            (string-ci<=? text "z")
            (string-ci>=? text "a")))))

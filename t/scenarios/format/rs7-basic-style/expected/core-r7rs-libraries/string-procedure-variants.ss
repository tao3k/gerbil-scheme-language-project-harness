;;; -*- Gerbil -*-
;;; Boundary: string comparisons, map/for-each, copy/fill/copy!.

(define-library (fixture rs7 basic string-procedures)
  (export string-variant-sample)
  (import (scheme base)
          (scheme char))
  (begin
    (define (string-variant-sample text)
      (let ((target (make-string (string-length text) #\space)))
        (string-copy! target 0 text)
        (string-fill! target #\x 1 (string-length target))
        (list (string=? text target)
              (string<? text target)
              (string>? text target)
              (string<=? text target)
              (string>=? text target)
              (string-ci=? text target)
              (string-ci<? text target)
              (string-ci>? text target)
              (string-map char-upcase text)
              (string-for-each (lambda (ch) ch) text)
              target)))))

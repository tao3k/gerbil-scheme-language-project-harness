;;; -*- Gerbil -*-
;;; Boundary: R7RS define-library declarations as source text.

(define-library (fixture rs7 basic library)
  (export render
          config)
  (import (scheme base)
          (scheme write))
  (include "library-body.scm")
  (begin
    (define config
      '((mode . strict)
        (format . rs7)))
    (define (render value)
      (write value))))

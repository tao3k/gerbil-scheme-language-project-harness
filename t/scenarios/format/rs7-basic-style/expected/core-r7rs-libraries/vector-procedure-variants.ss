;;; -*- Gerbil -*-
;;; Boundary: vector map/for-each/copy/copy!/append/fill variants.

(define-library (fixture rs7 basic vector-procedures)
  (export vector-variant-sample)
  (import (scheme base))
  (begin
    (define (vector-variant-sample vec)
      (let ((target (make-vector (vector-length vec) 'empty)))
        (vector-copy! target 0 vec)
        (vector-fill! target 'filled 1 (vector-length target))
        (list (vector-map (lambda (item) item) vec)
              (vector-for-each (lambda (item) item) vec)
              (vector-copy vec)
              (vector-copy vec 0 (vector-length vec))
              (vector-append vec target)
              target)))))

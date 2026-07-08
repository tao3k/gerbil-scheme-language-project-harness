;;; -*- Gerbil -*-
;;; Boundary: bytevector constructor/copy/copy!/append/fill variants.

(define-library (fixture rs7 basic bytevectors)
  (export bytevector-variant-sample)
  (import (scheme base))
  (begin
    (define (bytevector-variant-sample bytes)
      (let ((target (make-bytevector (bytevector-length bytes) 0)))
        (bytevector-copy! bytes 0 target 0 (bytevector-length bytes))
        (bytevector-u8-set! target 0 255)
        (list (bytevector 1 2 3)
              (bytevector-length target)
              (bytevector-u8-ref target 0)
              (bytevector-copy target)
              (bytevector-copy target 0 (bytevector-length target))
              (bytevector-append bytes target)))))

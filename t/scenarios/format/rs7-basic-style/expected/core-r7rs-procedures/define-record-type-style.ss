;;; -*- Gerbil -*-
;;; Boundary: R7RS define-record-type declarations and accessors.

(define-library (fixture rs7 basic records)
  (export make-point
          point?
          point-x
          point-y
          point-y-set!)
  (import (scheme base))
  (begin
    (define-record-type <point>
      (make-point x y)
      point?
      (x point-x)
      (y point-y point-y-set!))))

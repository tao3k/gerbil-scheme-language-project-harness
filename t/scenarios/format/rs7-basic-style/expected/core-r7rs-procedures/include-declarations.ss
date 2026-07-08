;;; -*- Gerbil -*-
;;; Boundary: include, include-ci, include-library-declarations declarations.

(define-library (fixture rs7 basic includes)
  (export included-value)
  (import (scheme base))
  (include "included-body.scm")
  (include-ci "included-case-folded.scm")
  (include-library-declarations "included-library-declarations.scm")
  (begin
    (define included-value 'present)))

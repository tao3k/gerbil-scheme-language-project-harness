;;; -*- Gerbil -*-
;;; Boundary: R7RS-small standard library import surface.

(define-library (fixture rs7 basic libraries)
  (export library-surface)
  (import (scheme base)
          (scheme case-lambda)
          (scheme char)
          (scheme complex)
          (scheme cxr)
          (scheme eval)
          (scheme file)
          (scheme inexact)
          (scheme lazy)
          (scheme load)
          (scheme process-context)
          (scheme read)
          (scheme repl)
          (scheme time)
          (scheme write))
  (begin
    (define library-surface
      'r7rs-small)))

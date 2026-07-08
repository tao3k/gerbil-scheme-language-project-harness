;;; -*- Gerbil -*-
;;; Boundary: process-context, time, and load library forms.

(define-library (fixture rs7 basic runtime-context)
  (export runtime-context-sample)
  (import (scheme base)
          (scheme load)
          (scheme process-context)
          (scheme time))
  (begin
    (define (runtime-context-sample path)
      (list (command-line)
            (get-environment-variable "HOME")
            (get-environment-variables)
            (current-second)
            (current-jiffy)
            (jiffies-per-second)
            (load path)
            (exit #t)
            (emergency-exit #f)))))

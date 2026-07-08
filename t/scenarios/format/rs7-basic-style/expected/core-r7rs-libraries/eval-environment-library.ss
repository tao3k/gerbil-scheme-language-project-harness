;;; -*- Gerbil -*-
;;; Boundary: eval library environment constructors.

(define-library (fixture rs7 basic eval)
  (export eval-environment-sample)
  (import (scheme base)
          (scheme eval))
  (begin
    (define (eval-environment-sample expression)
      (list (eval expression (environment '(scheme base)))
            (eval expression (scheme-report-environment 5))
            (eval expression (null-environment 5))))))

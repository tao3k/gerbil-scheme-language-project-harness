;;; -*- Gerbil -*-
;;; Boundary: repl library interaction-environment.

(define-library (fixture rs7 basic repl-complete)
  (export repl-complete-sample)
  (import (scheme base)
          (scheme eval)
          (scheme repl))
  (begin
    (define (repl-complete-sample expression)
      (eval expression (interaction-environment)))))

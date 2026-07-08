;;; -*- Gerbil -*-    
;;; Boundary: apply, map, for-each, call/cc alias, and call-with-port.    

(define-library (fixture rs7 basic procedure-syntax-complete)
  (export procedure-syntax-complete-sample)
  (import (scheme base))
  (begin
    (define (procedure-syntax-complete-sample proc values port)
      (call-with-port port
        (lambda (opened-port)
          (call/cc
            (lambda (return)
              (for-each
               (lambda (value)
                 (if (proc value)
                   (return value)
                   #!void))
               values)
              (apply list
                     (map proc values)))))))))    


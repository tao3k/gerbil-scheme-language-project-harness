;;; -*- Gerbil -*-    
;;; Boundary: read/write library variants and shared/simple output.    

(define-library (fixture rs7 basic read-write)
  (export read-write-sample)
  (import (scheme base)
          (scheme read)
          (scheme write))
  (begin
    (define (read-write-sample datum)
      (call-with-output-string
        (lambda (port)
          (write datum port)
          (write-shared datum port)
          (write-simple datum port)
          (display datum port)
          (newline port))))))    


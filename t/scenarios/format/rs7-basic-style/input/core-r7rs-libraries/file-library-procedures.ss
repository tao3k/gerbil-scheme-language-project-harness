;;; -*- Gerbil -*-    
;;; Boundary: file library and file-port procedure shape.    

(define-library (fixture rs7 basic file)
  (export file-procedure-sample)
  (import (scheme base)
          (scheme file)
          (scheme write))
  (begin
    (define (file-procedure-sample path datum)
      (call-with-output-file path
        (lambda (port)
          (write datum port)))
      (let ((exists? (file-exists? path)))
        (call-with-input-file path
          (lambda (port)
            (list exists?
                  (read port)
                  (delete-file path))))))))    


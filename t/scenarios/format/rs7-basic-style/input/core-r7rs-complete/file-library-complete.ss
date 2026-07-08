;;; -*- Gerbil -*-    
;;; Boundary: file library open and dynamic file redirection forms.    

(define-library (fixture rs7 basic file-complete)
  (export file-complete-sample)
  (import (scheme base)
          (scheme file)
          (scheme read)
          (scheme write))
  (begin
    (define (file-complete-sample path)
      (let ((input (open-input-file path))
            (binary-input (open-binary-input-file path))
            (output (open-output-file path))
            (binary-output (open-binary-output-file path)))
        (with-input-from-file path
          (lambda ()
            (read)))
        (with-output-to-file path
          (lambda ()
            (display "updated")))
        (list input binary-input output binary-output)))))    


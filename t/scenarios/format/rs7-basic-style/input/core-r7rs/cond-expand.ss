;;; -*- Gerbil -*-    
;;; Boundary: cond-expand feature clauses and library declarations.    

(define-library (fixture rs7 basic conditional)
  (cond-expand
   ((library (scheme write))
    (import (scheme write)))
   (r7rs
    (import (scheme base)))
   (else
    (import (scheme base))))
  (export selected-feature)
  (begin
    (define selected-feature
      'cond-expand)))    


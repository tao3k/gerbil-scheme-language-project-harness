;;; -*- Gerbil -*-    
;;; Boundary: complete library declaration grammar and nested import sets.    

(define-library (fixture rs7 basic 1 grammar)
  (export exported-name
          (rename hidden-name visible-name))
  (import (rename
           (prefix
            (except
             (only (scheme base) define lambda if set! begin)
             set!)
            base:)
           (base:lambda local-lambda)))
  (include "grammar-body.scm")
  (include-ci "grammar-body-folded.scm")
  (include-library-declarations "grammar-declarations.scm")
  (cond-expand
   ((and r7rs (library (scheme write)))
    (import (scheme write)))
   ((or gerbil gambit)
    (import (scheme base)))
   ((not missing-feature)
    (begin
      (define hidden-name 'visible)
      (define exported-name 'exported)))
   (else
    (begin
      (define hidden-name 'fallback)
      (define exported-name 'fallback)))))    


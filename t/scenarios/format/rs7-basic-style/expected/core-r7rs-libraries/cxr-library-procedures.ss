;;; -*- Gerbil -*-
;;; Boundary: cxr library selector family surface.

(define-library (fixture rs7 basic cxr)
  (export cxr-sample)
  (import (scheme base)
          (scheme cxr))
  (begin
    (define (cxr-sample tree)
      (list (caar tree)
            (cadr tree)
            (cdar tree)
            (cddr tree)
            (caaar tree)
            (caadr tree)
            (cadar tree)
            (caddr tree)
            (cdaar tree)
            (cdadr tree)
            (cddar tree)
            (cdddr tree)))))

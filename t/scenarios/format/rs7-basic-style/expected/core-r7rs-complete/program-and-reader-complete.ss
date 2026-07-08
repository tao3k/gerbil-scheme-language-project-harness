;;; -*- Gerbil -*-
;;; Boundary: R7RS program import, cond-expand, reader labels, nested comments.

(import (scheme base)
        (scheme write))

#|
Outer block comment.
#|
Nested block comment.
|#
|#

(cond-expand
 (r7rs
  (define selected-program-feature 'r7rs))
 ((and gerbil (not missing-feature))
  (define selected-program-feature 'gerbil))
 (else
  (define selected-program-feature 'fallback)))

(define reader-datum
  '#1=(root
       (self . #1#)
       (vector . #(#1#))))

(define quasiquote-datum
  (let ((items '(a b))
        (more '#(c d)))
    `(root
      ,@items
      #(vector ,@items)
      ,more)))

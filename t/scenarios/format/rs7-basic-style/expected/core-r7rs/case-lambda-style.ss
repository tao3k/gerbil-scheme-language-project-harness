;;; -*- Gerbil -*-
;;; Boundary: case-lambda as a common R7RS-small adjunct surface.

(import :gerbil/gambit)

(export make-formatter)

(def make-formatter
  (case-lambda
    (()
     (lambda (value) value))
    ((prefix)
     (lambda (value)
       (string-append prefix value)))
    ((prefix suffix)
     (lambda (value)
       (string-append prefix value suffix)))))

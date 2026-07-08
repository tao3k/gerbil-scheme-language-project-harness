;;; -*- Gerbil -*-
;;; Boundary: line comments, block comments, datum comments, booleans, chars.

(import :gerbil/gambit)

(export reader-samples)

#|
Block comments keep their internal text.
The formatter currently trims only line endings.
|#

(def (reader-samples)
  (list #t
        #f
        #\space
        "string with trailing spaces inside:   "
        '#(one two three)))

#; (list "ignored"
         "but still part of source text")

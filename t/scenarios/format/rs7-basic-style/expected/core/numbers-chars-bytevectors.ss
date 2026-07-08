;;; -*- Gerbil -*-
;;; Boundary: reader forms for numbers, chars, strings, vectors, bytevectors.

(import :gerbil/gambit)

(export literal-samples)

(def (literal-samples)
  (list 0
        -1
        3.14
        #x2a
        #o52
        #b101010
        #\newline
        #\x41
        "tabs stay inside strings:\t"
        '#(alpha 1 #t)
        '#u8(0 1 2 255)))

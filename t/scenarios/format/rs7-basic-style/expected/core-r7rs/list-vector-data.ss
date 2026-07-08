;;; -*- Gerbil -*-
;;; Boundary: lists, dotted pairs, vectors, bytevectors, and nested datum.

(import :gerbil/gambit)

(export datum-sample)

(def datum-sample
  '((proper list value)
    (dotted . pair)
    #(vector with #(nested vector))
    #u8(1 2 3 255)
    ((a . 1) (b . 2))
    #((tuple . value) #(inner))))

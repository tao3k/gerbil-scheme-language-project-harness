;;; -*- Gerbil -*-
;;; Boundary: vector, string, bytevector mutation and begin sequencing.

(import :gerbil/gambit)

(export mutate-sample)

(def (mutate-sample)
  (let ((text (string-copy "abc"))
        (items (vector 'a 'b 'c))
        (bytes (u8vector 1 2 3)))
    (begin
      (string-set! text 0 #\A)
      (vector-set! items 1 'B)
      (u8vector-set! bytes 2 9)
      [text items bytes])))

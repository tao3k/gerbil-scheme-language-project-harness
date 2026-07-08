;;; -*- Gerbil -*-
;;; Boundary: vector and bytevector constructors, accessors, mutation, copies.

(import :gerbil/gambit)

(export vector-bytevector-sample)

(def (vector-bytevector-sample)
  (let ((vec (vector 'a 'b 'c))
        (bytes (make-u8vector 4 0)))
    (vector-set! vec 1 'B)
    (u8vector-set! bytes 0 255)
    (list (make-vector 2 'x)
          vec
          (vector-length vec)
          (vector-ref vec 1)
          (vector->list vec)
          (list->vector '(1 2 3))
          bytes
          (u8vector-length bytes)
          (u8vector-ref bytes 0))))

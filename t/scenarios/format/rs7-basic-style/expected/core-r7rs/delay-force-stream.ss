;;; -*- Gerbil -*-
;;; Boundary: delay-force and lazy recursive stream shape.

(import :gerbil/gambit)

(export lazy-range)

(def (lazy-range start)
  (delay-force
    (cons start
          (lazy-range (+ start 1)))))

(def (lazy-head stream)
  (car (force stream)))

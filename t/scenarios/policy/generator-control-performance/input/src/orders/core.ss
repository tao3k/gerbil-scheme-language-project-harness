;;; -*- Gerbil -*-
;;; Orders generator facade.
(package: sample/orders)
(export sum-generated)

;; Number <- (Generating Number)
(def (sum-generated source)
  (let loop ((next source) (acc 0))
    (let (value (next))
      (if (eof-object? value)
        acc
        (loop next (+ acc value))))))

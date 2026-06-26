;;; -*- Gerbil -*-
;;; Orders generator facade.
(package: sample/orders)
(export sum-generated)

;; : (-> (Generating Number) Number)
(def (sum-generated source)
  (let loop ((next source) (acc 0))
    (let (value (next))
      (if (eof-object? value)
        acc
        (loop next (+ acc value))))))

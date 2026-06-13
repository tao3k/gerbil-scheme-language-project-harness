;;; -*- Gerbil -*-
(package: sample/control-flow)

(def (total xs)
  (let loop ((rest xs) (acc 0)) (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))

(def (plain-let x)
  (let ((value x)) value))

;;; -*- Gerbil -*-
(package: sample/poo-object-slots)

(.def base
  x: 0)

(.def (point @ [base] x)
  x
  y: 2
  total: (+ x y)
  level: => + 1
  child: =>.+ (.o z: 3)
  label: ? "unknown"
  (greeting (next-method) (string-append (next-method) "!")))

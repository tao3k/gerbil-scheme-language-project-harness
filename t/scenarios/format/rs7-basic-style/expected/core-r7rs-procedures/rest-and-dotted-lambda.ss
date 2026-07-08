;;; -*- Gerbil -*-
;;; Boundary: lambda fixed, rest, dotted, and mixed formal parameters.

(import :gerbil/gambit)

(export lambda-formals-sample)

(def lambda-formals-sample
  (list (lambda args args)
        (lambda (first . rest)
          (cons first rest))
        (lambda (first second . rest)
          (list first second rest))
        (lambda (first second)
          (+ first second))))

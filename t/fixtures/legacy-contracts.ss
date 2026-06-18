;;; -*- Gerbil -*-
(package sample/legacy-contracts)

;; (Z <- YY) <- (Z <- XX YY) XX
(def (sample-curry f x)
  (lambda (y) (f x y)))

;; (Generating B) <- (Generating A) (B <- A)
(def (sample-generating-map source transform)
  (generating-map source transform))

;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(package sample/formals)
;; SumTwo <- XX YY
(def (sum-two x y)
  (+ x y))
;; Collect <- (List XX)
(def (collect . xs)
  xs)

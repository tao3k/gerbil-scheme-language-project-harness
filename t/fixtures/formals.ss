;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(package sample/formals)
;; : (-> Number Number Number)
(def (sum-two x y)
  (+ x y))
;; : (-> (List Number) (List Number))
(def (collect . xs)
  xs)

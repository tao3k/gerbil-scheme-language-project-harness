;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
prelude: :gerbil/core
package: sample

(import :std/error)
(export answer make-answer)
;; Answer
(def answer 42)
;; MakeAnswer
(def (make-answer)
  answer)

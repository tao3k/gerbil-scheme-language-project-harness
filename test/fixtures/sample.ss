;;; -*- Gerbil -*-
prelude: :gerbil/core
package: sample

(import :std/error)
(export answer make-answer)

(def answer 42)

(def (make-answer)
  answer)


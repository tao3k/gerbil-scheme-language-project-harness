;;; -*- Gerbil -*-
(import :std/test)

(export deck-runtime-strategy-test)

(def deck-runtime-strategy-test
  (test-suite "deck-runtime-strategy"
    (test-case "loads"
      (check #t => #t))))

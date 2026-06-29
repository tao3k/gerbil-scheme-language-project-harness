;;; -*- Gerbil -*-
(import :std/test)

(export deck-runtime-condition-policy-test)

(def deck-runtime-condition-policy-test
  (test-suite "deck-runtime-condition-policy"
    (test-case "loads"
      (check #t => #t))))

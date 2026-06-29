;;; -*- Gerbil -*-
(import :std/test)

(export unit-a-test)

(def unit-a-test
  (test-suite "unit-a"
    (test-case "loads"
      (check #t => #t))))

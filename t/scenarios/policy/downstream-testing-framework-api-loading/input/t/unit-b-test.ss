;;; -*- Gerbil -*-
(import :std/test)

(export unit-b-test)

(def unit-b-test
  (test-suite "unit-b"
    (test-case "loads"
      (check #t => #t))))

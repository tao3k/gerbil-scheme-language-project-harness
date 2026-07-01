;;; -*- Gerbil -*-
(import :std/test)

(export scenario-b-test)

(def scenario-b-test
  (test-suite "scenario-b"
    (test-case "loads"
      (check #t => #t))))

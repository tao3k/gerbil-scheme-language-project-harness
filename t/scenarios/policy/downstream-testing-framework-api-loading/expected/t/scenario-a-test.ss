;;; -*- Gerbil -*-
(import :std/test)

(export scenario-a-test)

(def scenario-a-test
  (test-suite "scenario-a"
    (test-case "loads"
      (check #t => #t))))

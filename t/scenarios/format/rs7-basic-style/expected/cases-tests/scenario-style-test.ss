;;; -*- Gerbil -*-
;;; Boundary: test-style forms stay stable under whitespace cleanup.

(import :gerbil/gambit
        :std/test)

(export scenario-style-test)

(def scenario-style-test
  (test-suite "scenario style"
    (test-case "nested checks"
      (let (warnings ["one" "two"])
        (check (length warnings) => 2)
        (check (member "one" warnings) => '("one" "two"))))))

;;; -*- Gerbil -*-
(import :std/test
        :support/list
        :support/time)

(export support-test)

(def support-test
  (test-suite "gerbil scheme harness support helpers"
    (test-case "list helpers preserve stable order"
      (check (dedupe ["a" "b" "a" "c" "b"]) => ["a" "b" "c"])
      (check (take* ["a" "b" "c"] 2) => ["a" "b"])
      (check (take* ["a"] 3) => ["a"])
      (check (take* ["a"] 0) => '())
      (check (take* ["a"] -1) => '())
      (check (map-indexed
              (lambda (item index)
                (string-append (number->string index) ":" item))
              ["a" "b"])
             => ["1:a" "2:b"])
      (check (last ["a" "b" "c"]) => "c")
      (check (join ["a" "b" "c"] "/") => "a/b/c"))
    (test-case "time helpers normalize measured duration state"
      (check (duration-ms 10 25) => 15)
      (check (average-duration-ms 15 3) => 5)
      (check (duration-state 0) => "measured")
      (check (duration-state 12) => "measured")
      (check (duration-state -1) => "missing")
      (check (duration-state #f) => "missing"))))

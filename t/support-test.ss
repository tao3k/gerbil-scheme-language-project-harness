;;; -*- Gerbil -*-
(import :std/test
        :support/time)

(export support-test)
;; SupportTest
(def support-test
  (test-suite "gerbil scheme harness support helpers"
    (test-case "time helpers normalize measured duration state"
      (check (duration-ms 10 25) => 15)
      (check (average-duration-ms 15 3) => 5)
      (check (duration-state 0) => "measured")
      (check (duration-state 12) => "measured")
      (check (duration-state -1) => "missing")
      (check (duration-state #f) => "missing"))))

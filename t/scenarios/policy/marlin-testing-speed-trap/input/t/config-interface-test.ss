;;; -*- Gerbil -*-
(import :std/test)

(export config-interface-test)

(def config-interface-test
  (test-suite "config-interface"
    (test-case "loads"
      (check #t => #t))))

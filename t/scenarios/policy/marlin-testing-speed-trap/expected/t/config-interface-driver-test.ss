;;; -*- Gerbil -*-
(import :std/test)

(export config-interface-driver-test)

(def config-interface-driver-test
  (test-suite "config-interface-driver"
    (test-case "loads"
      (check #t => #t))))

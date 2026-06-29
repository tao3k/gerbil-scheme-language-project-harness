;;; -*- Gerbil -*-
;;; Fixture for gxtest runner failure propagation.

(import :std/test)
(export failing-local-suite-test)

(def failing-local-suite-test
  (test-suite "failing local suite"
    (test-case "intentional failure"
      (error "intentional failure"))))

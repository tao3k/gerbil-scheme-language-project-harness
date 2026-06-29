;;; -*- Gerbil -*-
(import :std/test)

(export test-setup! test-cleanup! alpha-test)

(def alpha-setup-ran #f)
(def alpha-cleanup-ran #f)

(def (test-setup!)
  (set! alpha-setup-ran #t))

(def (test-cleanup!)
  (set! alpha-cleanup-ran #t))

(def alpha-test
  (test-suite "upstream alpha"
    (test-case "setup is available to gxtest"
      (check (procedure? test-setup!) => #t))
    (test-case "cleanup is available to gxtest"
      (check (procedure? test-cleanup!) => #t))))

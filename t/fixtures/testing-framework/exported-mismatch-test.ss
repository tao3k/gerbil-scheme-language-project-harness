;;; -*- Gerbil -*-

(import :std/test)

(export poo-role-test)

(def poo-role-test
  (test-suite "exported mismatch"
    (test-case "suite symbol does not need to match the file name"
      (check #t => #t))))

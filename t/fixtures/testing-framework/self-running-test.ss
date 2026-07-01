;;; -*- Gerbil -*-

(import :std/test)

(run-tests!
 (test-suite "self-running"
   (test-case "top-level run-tests is a valid gxtest shape"
     (check #t => #t))))

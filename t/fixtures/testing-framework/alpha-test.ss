(import :std/test)

(def alpha-test
  (test-suite "alpha"
    (test-case "alpha ok"
      (check #t => #t))))

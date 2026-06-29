(import :std/test)

(def beta-test
  (test-suite "beta"
    (test-case "beta ok"
      (check #t => #t))))

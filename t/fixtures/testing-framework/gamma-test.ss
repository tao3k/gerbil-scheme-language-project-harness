(import :std/test)

(def gamma-test
  (test-suite "gamma"
    (test-case "gamma ok"
      (check #t => #t))))

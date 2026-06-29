(import :std/test)

(def delta-test
  (test-suite "delta"
    (test-case "delta ok"
      (check #t => #t))))

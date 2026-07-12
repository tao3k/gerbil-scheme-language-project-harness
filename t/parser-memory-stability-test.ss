;;; -*- Gerbil -*-
(import :std/test
        :gslph/src/parser/core
        :gslph/src/parser/profile
        (only-in :gslph/src/testing/memory-profile
                 declare-gxtest-memory-exception))

(export parser-memory-stability-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

(def parser-memory-stability-test
  (test-suite "parser profile memory stability"
    (test-case "caps default parser concurrency below full source packet pressure"
      (check (collect-project-default-worker-count 277 12) => 4)
      (check (collect-project-default-worker-count 3 12) => 3))
    (test-case "releases repeated fixture profile receipts"
      (let loop ((remaining 32) (expected-definition-count #f))
        (unless (zero? remaining)
          (let (next-definition-count expected-definition-count)
            (let* ((receipt
                    (collect-project/profile
                     "t/scenarios/policy/parser-combinator-boundary/input"))
                   (profile (hash-get receipt 'profile))
                   (definition-count (hash-get profile 'definitionCount))
                   (slowest-files (hash-get profile 'slowestFiles)))
              (check definition-count ? integer?)
              (when expected-definition-count
                (check definition-count => expected-definition-count))
              (check (<= (length slowest-files) 10) => #t)
              (set! next-definition-count definition-count)
              (set! slowest-files #f)
              (set! definition-count #f)
              (set! profile #f)
              (set! receipt #f))
            (##gc)
            (loop (- remaining 1) next-definition-count)))))))

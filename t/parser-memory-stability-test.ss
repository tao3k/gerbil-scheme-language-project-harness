;;; -*- Gerbil -*-
(import :std/test
        :gslph/src/parser/core)

(export parser-memory-stability-test)

(def +gxtest-memory-profile+
  '((maxHeapMiB . 768)))

(def parser-memory-stability-test
  (test-suite "parser profile memory stability"
    (test-case "releases repeated profile receipts within the managed heap"
      (let loop ((remaining 4))
        (unless (zero? remaining)
          (let* ((receipt (collect-project/profile "."))
                 (profile (hash-get receipt 'profile))
                 (definition-count (hash-get profile 'definitionCount))
                 (slowest-files (hash-get profile 'slowestFiles)))
            (check definition-count ? integer?)
            (check (<= (length slowest-files) 10) => #t)
            (set! slowest-files #f)
            (set! definition-count #f)
            (set! profile #f)
            (set! receipt #f))
          (##gc)
          (loop (- remaining 1)))))))

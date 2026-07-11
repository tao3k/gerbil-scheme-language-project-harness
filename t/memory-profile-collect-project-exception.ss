;;; -*- Gerbil -*-

(import :gerbil/gambit
        :std/test
        :gslph/src/parser/facade
        :gslph/src/testing/memory-profile)

(export memory-profile-collect-project-exception-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

(def memory-profile-collect-project-exception-test
  (test-suite "gxtest memory profile project-index exception"
    (test-case "bounds repeated project-index materialization"
      (let loop ((iteration 0))
        (when (< iteration 4)
          (let* ((receipt (collect-project/profile "."))
                 (profile (hash-get receipt 'profile)))
            (check (> (hash-get profile 'fileCount) 0) => #t)
            (check (number? (hash-get profile 'definitionCount)) => #t)
            (check (list? (hash-get profile 'slowestFiles)) => #t))
          (##gc)
          (loop (+ iteration 1)))))))

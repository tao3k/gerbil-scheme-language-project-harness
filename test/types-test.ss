;;; -*- Gerbil -*-
(import :std/test
        :parser
        :types)
(export types-test)

(def types-test
  (test-suite "gerbil scheme harness types"
    (test-case "reader errors become type pipeline findings"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "test/fixtures/invalid-read.fixture"))
             (findings (source-file-type-findings file))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding) => "GERBIL-SCHEME-READ-R001")
        (check (type-finding-severity finding) => "error")
        (check (type-finding-path finding) => "test/fixtures/invalid-read.fixture")))
    (test-case "duplicate definitions become type env facts"
      (let* ((first (make-type-binding "answer" "definition" "unknown"
                                       "same.ss" "same.ss:1-1"))
             (second (make-type-binding "answer" "definition" "unknown"
                                        "same.ss" "same.ss:2-2"))
             (duplicates (duplicate-type-bindings [first second]))
             (duplicate (car duplicates)))
        (check (length duplicates) => 1)
        (check (type-binding-selector (car duplicate)) => "same.ss:2-2")
        (check (type-binding-selector (cadr duplicate)) => "same.ss:1-1")))
    (test-case "same definition names in different owners are distinct"
      (let* ((first (make-type-binding "answer" "definition" "unknown"
                                       "first.ss" "first.ss:1-1"))
             (second (make-type-binding "answer" "definition" "unknown"
                                        "second.ss" "second.ss:2-2")))
        (check (duplicate-type-bindings [first second]) => '()))))

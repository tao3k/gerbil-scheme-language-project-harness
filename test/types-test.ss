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
        (check (type-finding-path finding) => "test/fixtures/invalid-read.fixture")))))

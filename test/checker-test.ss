;;; -*- Gerbil -*-
(import :std/test
        :checker
        :parser)
(export checker-test)

(def checker-test
  (test-suite "gerbil scheme harness checker"
    (test-case "parse errors become checker findings"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "test/fixtures/invalid-read.fixture"))
             (findings (source-file-findings file))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (finding-rule-id finding) => "GERBIL-SCHEME-READ-R001")
        (check (finding-severity finding) => "error")
        (check (finding-path finding) => "test/fixtures/invalid-read.fixture")))))

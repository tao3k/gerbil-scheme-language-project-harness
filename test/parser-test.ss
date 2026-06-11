;;; -*- Gerbil -*-
(import :std/test
        :parser)
(export parser-test)

(def parser-test
  (test-suite "gerbil scheme harness parser"
    (test-case "native reader captures package and definitions"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "test/fixtures/sample.ss")))
        (check (source-file-package file) => "sample/sample")
        (check (map definition-name (source-file-definitions file))
               => ["answer" "make-answer"])
        (check (map top-form-head (source-file-forms file))
               => ["import" "export" "def" "def"])
        (check (map top-form-kind (source-file-forms file))
               => ["import" "export" "definition" "definition"])
        (check (top-form-selector (car (source-file-forms file)))
               => "test/fixtures/sample.ss:5-5")))))

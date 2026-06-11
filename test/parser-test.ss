;;; -*- Gerbil -*-
(import :std/test
        :parser/parser)
(export parser-test)

(def parser-test
  (test-suite "gerbil scheme harness parser"
    (test-case "native reader captures package and definitions"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "test/fixtures/sample.ss")))
        (check (source-file-package file) => "sample/sample")
        (check (map definition-name (source-file-definitions file))
               => ["answer" "make-answer"])
        (check (map definition-formals (source-file-definitions file))
               => ['() '()])
        (check (map definition-arity (source-file-definitions file))
               => [0 0])
        (check (map top-form-head (source-file-forms file))
               => ["import" "export" "def" "def"])
        (check (map top-form-kind (source-file-forms file))
               => ["import" "export" "definition" "definition"])
        (check (top-form-selector (car (source-file-forms file)))
               => "test/fixtures/sample.ss:5-5")
        (check (source-file-line-count file) => 12)))
    (test-case "native reader captures definition formals"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "test/fixtures/formals.ss")))
        (check (map definition-name (source-file-definitions file))
               => ["sum-two" "collect"])
        (check (map definition-formals (source-file-definitions file))
               => [["x" "y"] ["xs"]])
        (check (map definition-arity (source-file-definitions file))
               => [2 1])))
    (test-case "native reader captures call facts"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "test/fixtures/formals.ss"))
             (calls (source-file-calls file)))
        (check (map call-fact-callee calls) => ["+"])
        (check (map call-fact-arity calls) => [2])
        (check (map call-fact-selector calls)
               => ["test/fixtures/formals.ss:4-5"])))))

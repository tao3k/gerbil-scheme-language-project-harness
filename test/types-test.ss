;;; -*- Gerbil -*-
(import :std/test
        :parser/facade
        :types/facade)
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
    (test-case "type env is built from native parser facts"
      (let* ((root (path-normalize "."))
             (index (collect-project root))
             (sample-bindings
              (filter (lambda (binding)
                        (equal? (type-binding-path binding)
                                "test/fixtures/formals.ss"))
                      (build-type-env index))))
        (check (map type-binding-name sample-bindings)
               => ["sum-two" "collect"])
        (check (map type-binding-kind sample-bindings)
               => ["def" "def"])
        (check (map type->string (map type-binding-type sample-bindings))
               => ["unknown" "unknown"])
        (check (map type-binding-formals sample-bindings)
               => [["x" "y"] ["xs"]])
        (check (map type-binding-arity sample-bindings)
               => [2 1])))
    (test-case "signature types merge into native type env"
      (let* ((root (path-normalize "."))
             (index (collect-project root))
             (signatures (load-type-signatures "test/fixtures/type-signatures.scm"))
             (sample-bindings
              (filter (lambda (binding)
                        (equal? (type-binding-path binding)
                                "test/fixtures/formals.ss"))
                      (build-type-env/signatures index signatures))))
        (check (map type-binding-name sample-bindings)
               => ["sum-two" "collect"])
        (check (map type->string (map type-binding-type sample-bindings))
               => ["(function (number number) number)" "(function (any) any)"])))
    (test-case "duplicate definitions become type env facts"
      (let* ((first (make-type-binding "answer" "definition" (make-type-unknown)
                                       '() 0 "same.ss" "same.ss:1-1"))
             (second (make-type-binding "answer" "definition" (make-type-unknown)
                                        '() 0 "same.ss" "same.ss:2-2"))
             (duplicates (duplicate-type-bindings [first second]))
             (duplicate (car duplicates)))
        (check (length duplicates) => 1)
        (check (type-binding-selector (car duplicate)) => "same.ss:2-2")
        (check (type-binding-selector (cadr duplicate)) => "same.ss:1-1")))
    (test-case "same definition names in different owners are distinct"
      (let* ((first (make-type-binding "answer" "definition" (make-type-unknown)
                                       '() 0 "first.ss" "first.ss:1-1"))
             (second (make-type-binding "answer" "definition" (make-type-unknown)
                                        '() 0 "second.ss" "second.ss:2-2")))
        (check (duplicate-type-bindings [first second]) => '())))))

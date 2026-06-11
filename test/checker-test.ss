;;; -*- Gerbil -*-
(import :std/test
        :checker/checker
        :parser/parser
        :types/types)
(export checker-test)

(def checker-test
  (test-suite "gerbil scheme harness checker"
    (test-case "arity checker reports signature mismatches from native calls"
      (let* ((root (path-normalize "."))
             (index (collect-project root))
             (signatures (load-type-signatures "test/fixtures/type-signatures.scm"))
             (findings (run-arity-checks index signatures))
             (fixture-findings
              (filter (lambda (finding)
                        (equal? (type-finding-path finding)
                                "test/fixtures/formals.ss"))
                      findings))
             (finding (car fixture-findings)))
        (check (length fixture-findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-A001")
        (check (type-finding-severity finding) => "error")
        (check (type-finding-selector finding)
               => "test/fixtures/formals.ss:4-5")
        (check (type-finding-message finding)
               => "arity mismatch for +: expected 3, got 2")))
    (test-case "type check pipeline includes checker findings with signatures"
      (let* ((root (path-normalize "."))
             (index (collect-project root))
             (signatures (load-type-signatures "test/fixtures/type-signatures.scm"))
             (findings (run-type-checks/signatures index signatures))
             (rule-ids (map type-finding-rule-id findings)))
        (check (not (not (member "GERBIL-SCHEME-CHECKER-A001" rule-ids)))
               => #t)))))

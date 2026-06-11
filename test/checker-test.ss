;;; -*- Gerbil -*-
(import :gerbil/gambit
        :std/test
        :checker/facade
        :parser/facade
        :types/facade)
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
    (test-case "native whitelist checker rejects unlisted external calls"
      (let* ((root ".run/checker-whitelist")
             (_ (write-whitelist-project root))
             (index (collect-project root))
             (whitelist (load-call-whitelist
                         ".run/checker-whitelist/allowed-calls.txt"))
             (findings (run-whitelist-checks index whitelist))
             (finding (car findings)))
        (check whitelist => ["allowed"])
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-W001")
        (check (type-finding-path finding) => "src/sample.ss")
        (check (type-finding-message finding)
               => "call to danger is not in the native call whitelist")))
    (test-case "type check pipeline includes whitelist findings when configured"
      (let* ((root ".run/checker-whitelist-pipeline")
             (_ (write-whitelist-project root))
             (index (collect-project root))
             (findings (run-type-checks/whitelist index '() ["allowed"]))
             (rule-ids (map type-finding-rule-id findings)))
        (check (not (not (member "GERBIL-SCHEME-CHECKER-W001" rule-ids)))
               => #t)))
    (test-case "type check pipeline includes checker findings with signatures"
      (let* ((root (path-normalize "."))
             (index (collect-project root))
             (signatures (load-type-signatures "test/fixtures/type-signatures.scm"))
             (findings (run-type-checks/signatures index signatures))
             (rule-ids (map type-finding-rule-id findings)))
        (check (not (not (member "GERBIL-SCHEME-CHECKER-A001" rule-ids)))
               => #t)))))

(def (write-whitelist-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss"))
         (whitelist-path (string-append root "/allowed-calls.txt")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(def (safe x) (allowed x))\n(def (unsafe x) (danger x))\n")
    (write-text whitelist-path
                "; comment lines are ignored\nallowed\n\n")))

(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))

(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))

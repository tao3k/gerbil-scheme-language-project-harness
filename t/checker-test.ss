;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :gerbil/gambit
        :std/test
        :checker/facade
        :parser/facade
        :types/facade)
(export checker-test)
;; CheckerTest
(def checker-test
    (test-suite "gerbil scheme harness checker"
    (test-case "arity checker reports signature mismatches from native calls"
      (let* ((root ".run/checker-arity")
             (_ (write-arity-project root))
             (index (collect-project root))
             (signatures
              (load-type-signatures
               ".run/checker-arity/type-signatures.scm"))
             (findings (run-arity-checks index signatures))
             (fixture-findings
              (filter (lambda (finding)
                        (equal? (type-finding-path finding)
                                "src/sample.ss"))
                      findings))
             (finding (car fixture-findings)))
        (check (length fixture-findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-A001")
        (check (type-finding-severity finding) => "error")
        (check (type-finding-selector finding)
               => "src/sample.ss:5-5")
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
    (test-case "macro governance checker allows harness source macro forms"
      (let* ((root ".run/checker-harness-macros")
             (_ (write-harness-macro-project root))
             (index (collect-project root))
             (findings (run-macro-governance-checks index)))
        (check findings => [])))
    (test-case "macro governance checker rejects generated macro forms without policy"
      (let* ((root ".run/checker-macro-governance")
             (_ (write-generated-macro-project root))
             (index (collect-project root))
             (findings (run-macro-governance-checks index))
             (rule-ids (map type-finding-rule-id findings))
             (paths (map type-finding-path findings)))
        (check (length findings) => 2)
        (check rule-ids
               => ["GERBIL-SCHEME-CHECKER-W002"
                   "GERBIL-SCHEME-CHECKER-W002"])
        (check paths => ["generated/sample.ss" "generated/sample.ss"])
        (check (type-finding-message (car findings))
               => "macro form define-syntax in generated-code requires POO macro-governance policy with clear user explanation and witness")))
    (test-case "macro governance checker allows generated macro forms with clear package policy"
      (let* ((root ".run/checker-macro-governance-policy")
             (_ (write-generated-macro-project
                 root
                 ";;; -*- Gerbil -*-\n(package: sample\n  policy: ((macro-governance allow-generated: #t explanation: \"User-owned generated macro fixture exercises a local DSL that cannot be expressed cleanly as first-order functions.\" witness: \"t/checker-test.ss:macro-governance\")))\n"))
             (index (collect-project root))
             (findings (run-macro-governance-checks index)))
        (check findings => [])))
    (test-case "macro governance checker rejects generated macro policy without clear witness"
      (let* ((root ".run/checker-macro-governance-short-policy")
             (_ (write-generated-macro-project
                 root
                 ";;; -*- Gerbil -*-\n(package: sample\n  policy: ((macro-governance allow-generated: #t explanation: \"temporary\" witness: \"soon\")))\n"))
             (index (collect-project root))
             (findings (run-macro-governance-checks index)))
        (check (length findings) => 2)))
    (test-case "type check pipeline includes macro governance findings"
      (let* ((root ".run/checker-macro-governance-pipeline")
             (_ (write-generated-macro-project root))
             (index (collect-project root))
             (findings (run-type-checks index))
             (rule-ids (map type-finding-rule-id findings)))
        (check (not (not (member "GERBIL-SCHEME-CHECKER-W002" rule-ids)))
               => #t)))
    (test-case "type check pipeline includes checker findings with signatures"
      (let* ((root (path-normalize "."))
             (index (collect-project root))
             (signatures (load-type-signatures "t/fixtures/type-signatures.scm"))
             (findings (run-type-checks/signatures index signatures))
             (rule-ids (map type-finding-rule-id findings)))
        (check (not (not (member "GERBIL-SCHEME-CHECKER-A001" rule-ids)))
               => #t)))
    (test-case "type mismatch checker reports known argument mismatches"
      (let* ((root ".run/checker-type-mismatch")
             (_ (write-type-mismatch-project root))
             (index (collect-project root))
             (signatures (load-type-signatures
                          ".run/checker-type-mismatch/type-signatures.scm"))
             (findings (run-type-mismatch-checks index signatures))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-T001")
        (check (type-finding-path finding) => "src/sample.ss")
        (check (type-finding-message finding)
               => "type mismatch for needs-string argument 0: expected string, got number")))
    (test-case "type mismatch checker reports literal argument mismatches"
      (let* ((root ".run/checker-literal-type-mismatch")
             (_ (write-literal-type-mismatch-project root))
             (index (collect-project root))
             (signatures (load-type-signatures
                          ".run/checker-literal-type-mismatch/type-signatures.scm"))
             (findings (run-type-mismatch-checks index signatures))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-T001")
        (check (type-finding-message finding)
               => "type mismatch for needs-string argument 0: expected string, got number")))
    (test-case "type mismatch checker reports local literal binding mismatches"
      (let* ((root ".run/checker-local-binding-type-mismatch")
             (_ (write-local-binding-type-mismatch-project root))
             (index (collect-project root))
             (signatures (load-type-signatures
                          ".run/checker-local-binding-type-mismatch/type-signatures.scm"))
             (findings (run-type-mismatch-checks index signatures))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-T001")
        (check (type-finding-message finding)
               => "type mismatch for needs-string argument 0: expected string, got number")))
    (test-case "type mismatch checker reports local alias binding mismatches"
      (let* ((root ".run/checker-local-alias-type-mismatch")
             (_ (write-local-alias-type-mismatch-project root))
             (index (collect-project root))
             (signatures (load-type-signatures
                          ".run/checker-local-alias-type-mismatch/type-signatures.scm"))
             (findings (run-type-mismatch-checks index signatures))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-CHECKER-T001")
        (check (type-finding-message finding)
               => "type mismatch for needs-string argument 0: expected string, got number")))
    (test-case "type check pipeline includes type mismatch findings"
      (let* ((root ".run/checker-type-mismatch-pipeline")
             (_ (write-type-mismatch-project root))
             (index (collect-project root))
             (signatures (load-type-signatures
                          ".run/checker-type-mismatch-pipeline/type-signatures.scm"))
             (findings (run-type-checks/signatures index signatures))
             (rule-ids (map type-finding-rule-id findings)))
        (check (not (not (member "GERBIL-SCHEME-CHECKER-T001" rule-ids)))
               => #t)))))
;; : (-> String Unit )
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
;; : (-> String Unit )
(def (write-arity-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss"))
         (signature-path (string-append root "/type-signatures.scm")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(package: sample/checker)\n;; : (-> Number Number Number)\n(def (sum-two x y)\n  (+ x y))\n")
    (write-text signature-path
                "((+ . (function (number number number) number))\n (sum-two . (function (number number) number)))\n")))
;; : (-> String Unit )
(def (write-harness-macro-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(define-syntax unsafe-macro #f)\n(syntax-case input () ((_ x) #'x))\n(def (safe x) x)\n")))
;; : (-> String MaybePackageSource Unit )
(def (write-generated-macro-project root . maybe-package-source)
  (let* ((generated (string-append root "/generated"))
         (source-path (string-append generated "/sample.ss"))
         (package-path (string-append root "/gerbil.pkg")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir generated)
    (if (pair? maybe-package-source)
      (write-text package-path (car maybe-package-source))
      (delete-file-if-exists package-path))
    (write-text source-path
                ";;; -*- Gerbil -*-\n(define-syntax generated-macro #f)\n(syntax-case input () ((_ x) #'x))\n(def (safe x) x)\n")))
;; : (-> String Unit )
(def (write-type-mismatch-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss"))
         (signature-path (string-append root "/type-signatures.scm")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(def (needs-string value) value)\n(def (use-number n) (needs-string n))\n(def (use-string s) (needs-string s))\n")
    (write-text signature-path
                "((needs-string . (function (string) string))\n (use-number . (function (number) number))\n (use-string . (function (string) string)))\n")))
;; : (-> String Unit )
(def (write-literal-type-mismatch-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss"))
         (signature-path (string-append root "/type-signatures.scm")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(def (needs-string value) value)\n(def good (needs-string \"ok\"))\n(def bad (needs-string 10))\n")
    (write-text signature-path
                "((needs-string . (function (string) string)))\n")))
;; : (-> String Unit )
(def (write-local-binding-type-mismatch-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss"))
         (signature-path (string-append root "/type-signatures.scm")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(def (needs-string value) value)\n(def (use-let)\n  (let ((value \"ok\") (bad 10))\n    (needs-string value)\n    (needs-string bad)))\n")
    (write-text signature-path
                "((needs-string . (function (string) string)))\n")))
;; : (-> String Unit )
(def (write-local-alias-type-mismatch-project root)
  (let* ((src (string-append root "/src"))
         (source-path (string-append src "/sample.ss"))
         (signature-path (string-append root "/type-signatures.scm")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text source-path
                ";;; -*- Gerbil -*-\n(def (needs-string value) value)\n(def (use-let-star)\n  (let* ((value \"ok\")\n         (alias value)\n         (bad 10)\n         (bad-alias bad))\n    (needs-string alias)\n    (needs-string bad-alias)))\n")
    (write-text signature-path
                "((needs-string . (function (string) string)))\n")))
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> String DeleteFileIfExists )
(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))

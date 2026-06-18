;;; -*- Gerbil -*-
;;; Gerbil scheme harness policy source scope self-audit tests.

(import :gerbil/gambit
        :std/test
        :parser/facade
        :policy/facade
        :policy/fixtures
        :types/facade)

(export agent-source-scope-policy-test)

;; PolicyTest
(def agent-source-scope-policy-test
  (test-suite "gerbil scheme harness policy source scope"
    (test-case "agent policy rejects policy path scope hardcoding"
      (let* ((root ".run/policy-source-scope-hardcoded")
             (source-dir (string-append root "/src/policy")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/policy-scope)\n")
        (write-text
         (string-append source-dir "/bad.ss")
         ";;; -*- Gerbil -*-\n(import (only-in :std/srfi/13 string-prefix?))\n(def (policy-file? path)\n  (not (string-prefix? \"t/scenarios/\" path)))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-R021" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/policy/bad.ss")
          (check (hash-get details 'kind) => "policy-source-scope")
          (check (hash-get details 'parserOwner) => "src/parser/source-class.ss"))))
    (test-case "agent policy accepts parser-owned source class scope"
      (let* ((root ".run/policy-source-scope-class")
             (source-dir (string-append root "/src/policy")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/policy-scope)\n")
        (write-text
         (string-append source-dir "/good.ss")
         ";;; -*- Gerbil -*-\n(import :parser/facade)\n(def (policy-file? path)\n  (not (equal? (source-path-class path) \"policy-scenario\")))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-R021" findings)))
          (check matching => []))))))


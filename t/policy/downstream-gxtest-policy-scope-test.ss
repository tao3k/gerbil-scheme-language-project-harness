;;; -*- Gerbil -*-
;;; Downstream gxtest policy-scope regression scenario.

(import :std/test
        :policy/agent-style-support
        :policy/gxtest
        :scenario/policy
        :types/facade)

(export downstream-gxtest-policy-scope-test)

(def +downstream-gxtest-policy-scope-scenario+
  "downstream-gxtest-policy-scope")

;; PolicyTest
(def downstream-gxtest-policy-scope-test
  (test-suite "downstream gxtest policy scope scenario"
    (test-case "build test scope policy reaches imported source owner"
      (let* ((scenario-id +downstream-gxtest-policy-scope-scenario+)
             (context (agent-style-policy-r013-scenario-context scenario-id))
             (scenario
              (make-policy-scenario
               scenario-id
               (agent-style-policy-scenario-path scenario-id)))
             (input-report
              (policy-report (policy-scenario-input-root scenario)
                             ["t/unit-tests.ss"]))
             (expected-report
              (policy-report (policy-scenario-expected-root scenario)
                             ["t/unit-tests.ss"]))
             (input-findings (hash-get input-report 'findings))
             (input-r013
              (filter (lambda (finding)
                        (equal? (type-finding-rule-id finding)
                                "GERBIL-SCHEME-AGENT-R013"))
                      input-findings)))
        (agent-style-check-r013-scenario!
         context
         scenario-id
         "downstream-gxtest-policy-scope")
        (agent-style-check-r013-scenario-learning!
         context
         ["gerbil://" "gerbil-utils"]
         ["downstream-gxtest"
          "gxtest-policy-scope"
          "anti-ai-scaffold"])
        (check (hash-get input-report 'scope) => "files")
        (check (hash-get input-report 'requestedFiles) => ["t/unit-tests.ss"])
        (check (hash-get input-report 'status) => "fail")
        (check (hash-get input-report 'files) => 4)
        (check (length input-r013) => 1)
        (check (type-finding-path (car input-r013)) => "src/cli.ss")
        (check (hash-get expected-report 'status) => "pass")))))

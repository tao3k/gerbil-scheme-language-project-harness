;;; -*- Gerbil -*-
;;; gerbil scheme harness agent basic policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :commands/check
        :parser/facade
        :policy/facade
        :policy/gxtest
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export agent-basic-policy-test)
;; PolicyTest
(def agent-basic-policy-test
  (test-suite "gerbil scheme harness agent basic policy"
    (test-case "agent policy requires facade intent comment"
          (let* ((root ".run/policy-agent")
                 (_ (write-facade-policy-project
                     root "bar"
                     ";;; -*- Gerbil -*-\n(export value)\n"
                     ";;; -*- Gerbil -*-\n;;; Bar core.\n(def value 1)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R001" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R001")
            (check (type-finding-path finding) => "src/bar/facade.ss")))
    (test-case "agent policy rejects generic owner names"
          (let* ((root ".run/policy-generic-owner")
                 (_ (write-facade-policy-project
                     root "utils"
                     ";;; -*- Gerbil -*-\n;;; Utilities facade.\n(export value)\n"
                     ";;; -*- Gerbil -*-\n;;; Utilities core.\n(def value 1)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R002" findings))
                 (finding (car matching)))
            (check (length matching) => 2)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R002")
            (check (not (not (member "src/utils/facade.ss"
                                      (map type-finding-path matching))))
                   => #t)))
    (test-case "agent policy rejects vague definition names"
          (let* ((root ".run/policy-vague-definition")
                 (_ (write-vague-definition-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R004" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R004")
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:3-3")))
    (test-case "package agent-policy disables selected rules"
          (let* ((root ".run/policy-agent-disabled-rule")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders\n  policy: ((agent-policy disabled-rules: (\"GERBIL-SCHEME-AGENT-R004\") explanation: \"Fixture owns the vague-definition regression separately.\")))\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (process order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R004" findings)))
              (check matching => []))))
    (test-case "agent policy rejects top-level executable calls in src"
          (let* ((root ".run/policy-top-level-executable")
                 (_ (write-top-level-executable-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R005" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R005")
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:3-3")
            (check (type-finding-message finding)
                   => "top-level executable call displayln should move behind a named definition or explicit entrypoint")))
    (test-case "agent policy accepts explicit search-fast entrypoints"
          (let* ((root ".run/policy-search-fast-entrypoint")
                 (_ (write-search-fast-entrypoint-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R005" findings)))
            (check matching => [])))
    (test-case "agent policy accepts exported main script entrypoints"
      (let* ((root ".run/policy-exported-main-entrypoint")
             (src (string-append root "/src"))
             (owner (string-append src "/tools")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
            (ensure-dir owner)
            (write-text
             (string-append owner "/run.ss")
             ";;; -*- Gerbil -*-\n(export main)\n(def (main . args) 0)\n(exit (apply main (cdr (command-line))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R005" findings)))
              (check matching => []))))
    (test-case "agent policy accepts explicit test harness entrypoints"
      (let* ((root ".run/policy-test-harness-entrypoint")
             (test-root (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir test-root)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/test-harness-entrypoint)\n")
        (write-text
         (string-append test-root "/sample-test.ss")
         ";;; -*- Gerbil -*-\n(import :std/test)\n(def (subject) 1)\n(run-tests!\n (test-suite \"sample\"\n   (test-case \"works\"\n     (check (subject) => 1))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-R005" findings)))
          (check matching => []))))
    (test-case "agent policy treats FFI declare body as declarative range"
          (let* ((root ".run/policy-ffi-declare-declarative")
                 (_ (write-ffi-declare-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R005" findings)))
            (check matching => [])))
    (test-case "agent policy treats POO declarative bodies as declarative ranges"
          (let* ((root ".run/policy-poo-declarative-range")
                 (_ (write-poo-declarative-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R005" findings)))
            (check matching => [])))
    (test-case "check changed scope reports only changed-file policy findings"
          (let* ((root ".run/policy-check-changed-scope")
                 (_ (write-check-changed-project root))
                 (_ (initialize-git-fixture root))
                 (_ (write-text (string-append root "/src/changed/core.ss")
                                ";;; -*- Gerbil -*-\n(package: sample/changed)\n(def (process x) x)\n"))
             (result (policy-check-output ["--changed" root]))
                 (output (cdr result)))
            (check (car result) => 1)
            (check (not (not (string-contains output "scope=changed"))) => #t)
            (check (not (not (string-contains output "src/changed/core.ss"))) => #t)
            (check (not (string-contains output "src/stable/core.ss")) => #t)))
    (test-case "agent policy preserves named-let control contexts"
          (let* ((root ".run/policy-functional-idiom-control-context")
                 (_ (write-functional-idiom-control-context-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R009" findings)))
            (check matching => [])))
    (test-case "agent policy accepts explicit higher-order idiom"
          (let* ((root ".run/policy-functional-idiom-positive")
                 (_ (write-functional-idiom-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R009" findings)))
            (check (length matching) => 0)))
    (test-case "agent policy keeps functional idiom suppression caller scoped"
          (let* ((root ".run/policy-functional-idiom-caller-scope")
                 (_ (write-functional-idiom-caller-scope-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R009" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-selector finding) => "src/orders/core.ss:7-8")
            (check (hash-get (type-finding-details finding) 'caller)
                   => "manual-total")))
    (test-case "agent policy preserves native reader loops"
          (let* ((root ".run/policy-functional-idiom-reader")
                 (_ (write-functional-idiom-reader-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R009" findings)))
            (check (length matching) => 0)))))

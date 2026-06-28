;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO guidance policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :commands/check
        :parser/facade
        :policy/facade
        :policy/gxtest
        :scenario/policy
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-poo-support)
(export agent-poo-guidance-policy-test)

;; PolicyTest
(def agent-poo-guidance-policy-test
  (test-suite "gerbil scheme harness agent POO guidance policy"
(test-case "POO performance scenarios own benchmark contracts"
      (check (missing-poo-performance-scenario-benchmarks
              +poo-performance-scenario-ids+)
             => []))
(test-case "POO performance scenarios declare hot-path exemption evidence"
      (check (poo-performance-scenarios-missing-hot-path-exemptions
              +poo-performance-scenario-ids+)
             => []))
(test-case "agent policy rewrites real dashboard POO workflow to boundary APIs"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-real-dashboard-workflow-performance"
                   "t/scenarios/policy/poo-real-dashboard-workflow-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-findings
                  (policy-scenario-findings/rules
                   result
                   'before
                   +poo-real-dashboard-workflow-rule-ids+))
                 (after-findings
                  (policy-scenario-findings/rules
                   result
                   'after
                   +poo-real-dashboard-workflow-rule-ids+)))
            (check (hash-get timing 'schemaId)
                   => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
            (check (hash-get timing 'scenarioId)
                   => "poo-real-dashboard-workflow-performance")
            (check (length timings) => 4)
            (check (policy-scenario-timing-steps-measured? timings)
                   => #t)
            (check (policy-scenario-benchmark-constrained? timing)
                   => #t)
            (check (policy-scenario-benchmark-targeted? timing)
                   => #t)
            (check (hash-get timing 'targetStatus)
                   => "pass")
            (check (>= (length before-findings) 7) => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-028" before-findings)
                   => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-029" before-findings)
                   => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-030" before-findings)
                   => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-031" before-findings)
                   => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-033" before-findings)
                   => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-035" before-findings)
                   => #t)
            (check (policy-rule-present?
                    "GERBIL-SCHEME-AGENT-POLICY-037" before-findings)
                   => #t)
            (check after-findings => [])))
(test-case "agent policy rejects direct POO writeenv calls"
          (let* ((root ".run/policy-poo-direct-writeenv")
                 (_ (write-poo-direct-writeenv-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-006" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-006")
            (check (type-finding-path finding) => "src/orders/io.ss")
            (check (type-finding-message finding)
                   => "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first")))
(test-case "agent policy requires runtime-source witness for POO IO overrides"
          (let* ((root ".run/policy-poo-io-runtime-witness")
                 (_ (write-poo-io-override-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-007" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-007")
            (check (type-finding-path finding) => "src/orders/io.ss")
            (check (type-finding-message finding)
                   => "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified")))
(test-case "agent policy requires POO method generic and class facts"
          (let* ((root ".run/policy-poo-method-shape")
                 (_ (write-poo-method-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-008" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-008")
            (check (type-finding-path finding) => "src/orders/methods.ss")
            (check (type-finding-message finding)
                   => "POO method order-discount is missing parser-owned defgeneric,defclass-or-defprotocol facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")))
(test-case "agent policy requires POO usage documentation for defaults and slot mutation"
          (let* ((root ".run/policy-poo-documentation-usage")
                 (_ (write-poo-documentation-usage-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-038" findings))
                 (finding (car matching))
                 (details (type-finding-details finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/docs.ss")
            (check (type-finding-message finding)
                   => "POO defaults and slot mutation APIs need a full-form typed doc with body, result example, and POO usage terms")
            (check (not (not (member ".putdefault!" (hash-get details 'apiCallees))))
                   => #t)
            (check (not (not (member "setslots!" (hash-get details 'apiCallees))))
                   => #t)
            (check (hash-get details 'triggerApis)
                   => ".putslot!,.putdefault!,.setslot!,.setslots!,.set!,putslot!,putdefault!,setslot!,setslots!")
            (check (hash-get details 'coveredApis)
                   => ".o,.def,defpoo,.mix,.ref,.get,.putslot!,.putdefault!,.setslot!,.setslots!,.set!,putslot!,putdefault!,setslot!,setslots!")))
(test-case "agent policy accepts documented POO usage for defaults and slot mutation"
          (let* ((root ".run/policy-poo-documentation-usage-positive")
                 (_ (write-poo-documentation-usage-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-038" findings)))
            (check matching => [])))
(test-case "agent policy redirects outer POO constructor slot projection to prototype fixed point"
          (let* ((root ".run/policy-poo-prototype-fixed-point")
                 (_ (write-poo-prototype-fixed-point-drift-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-026" findings))
                 (finding (car matching))
                 (details (type-finding-details finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (hash-get details 'constructor) => "make-order")
            (check (hash-get details 'projectionCount) => 2)
            (check (hash-get details 'guidanceMode) => "soft-warning")
            (check (hash-get details 'allowedUse)
                   => "isolated .ref/.@/.get boundary reads are valid POO API usage")
            (check (hash-get details 'docsPath)
                   => "docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org")
            (check (hash-get details 'preferredSyntax)
                   => "{(:: @ super) slot: ...}, =>, =>.+, ?, .mix")))
(test-case "agent policy accepts prototype-local POO fixed point syntax"
          (let* ((root ".run/policy-poo-prototype-fixed-point-positive")
                 (_ (write-poo-prototype-fixed-point-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-026" findings)))
            (check matching => [])))
(test-case "agent policy allows isolated POO boundary reads without usage docs"
          (let* ((root ".run/policy-poo-documentation-boundary-read")
                 (_ (write-poo-prototype-boundary-read-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-038" findings)))
            (check matching => [])))
(test-case "agent policy does not treat ordinary Scheme set! as POO usage"
          (let* ((root ".run/policy-poo-documentation-ordinary-set")
                 (_ (write-poo-documentation-ordinary-set-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-038" findings)))
            (check matching => [])))
(test-case "agent policy allows isolated POO slot boundary reads"
          (let* ((root ".run/policy-poo-prototype-boundary-read")
                 (_ (write-poo-prototype-boundary-read-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-026" findings)))
            (check matching => [])))
(test-case "agent policy redirects large data-shaped POO object construction to object<-alist"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-construction-performance"
                   "t/scenarios/policy/poo-construction-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-027"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-027"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (hash-get timing 'schemaId)
                     => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
              (check (hash-get timing 'scenarioId)
                     => "poo-construction-performance")
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/profile.ss")
              (check (hash-get details 'kind)
                     => "poo-construction-performance")
              (check (hash-get details 'callee) => ".o")
              (check (hash-get details 'slotSpecCount) => 16)
              (check (hash-get details 'slotSpecThreshold) => 12)
              (check (hash-get details 'preferredConstruction)
                     => "object<-alist for broad mostly-data POO values")))
  ))

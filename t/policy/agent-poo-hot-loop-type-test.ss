;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO hot loop type policy.

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
(export agent-poo-hot-loop-type-policy-test)

;; PolicyTest
(def agent-poo-hot-loop-type-policy-test
  (test-suite "gerbil scheme harness agent POO hot loop type policy"
(test-case "agent policy redirects loop-local POO lens modification to a boundary update"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-lens-loop-performance"
                   "t/scenarios/policy/poo-lens-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R032"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R032"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/lens.ss")
              (check (hash-get details 'kind)
                     => "poo-lens-loop-performance")
              (check (hash-get details 'callee) => ".call")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "accumulate scalar lens target state and apply one final .cc outside the loop")))
(test-case "agent policy redirects loop-local POO object construction to one boundary object"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-object-construction-loop-performance"
                   "t/scenarios/policy/poo-object-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R033"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R033"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/construct.ss")
              (check (hash-get details 'kind)
                     => "poo-object-construction-loop-performance")
              (check (hash-get details 'callee) => "object<-hash")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable object construction or accumulate scalar/list/hash state and construct one final POO object")))
(test-case "agent policy redirects loop-local POO type construction to a named type binding"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-type-construction-loop-performance"
                   "t/scenarios/policy/poo-type-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R034"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R034"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/type.ss")
              (check (hash-get details 'kind)
                     => "poo-type-construction-loop-performance")
              (check (hash-get details 'callee) => "MonomorphicObject")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable POO/MOP type objects to a named binding outside the loop")))
(test-case "agent policy redirects loop-local POO function type construction to a named type binding"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-function-type-construction-loop-performance"
                   "t/scenarios/policy/poo-function-type-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R034"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R034"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/function-type.ss")
              (check (hash-get details 'kind)
                     => "poo-type-construction-loop-performance")
              (check (hash-get details 'callee) => "Function")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable POO/MOP type objects to a named binding outside the loop")))
(test-case "agent policy redirects loop-local POO finite-field type construction to a named type binding"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-fq-type-construction-loop-performance"
                   "t/scenarios/policy/poo-fq-type-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R034"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R034"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/finite-field.ss")
              (check (hash-get details 'kind)
                     => "poo-type-construction-loop-performance")
              (check (hash-get details 'callee) => "F_q")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable POO/MOP type objects to a named binding outside the loop")))
(test-case "agent policy redirects loop-local POO modular type construction to a named type binding"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-z-type-construction-loop-performance"
                   "t/scenarios/policy/poo-z-type-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R034"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R034"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/modular.ss")
              (check (hash-get details 'kind)
                     => "poo-type-construction-loop-performance")
              (check (hash-get details 'callee) => "Z/")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable POO/MOP type objects to a named binding outside the loop")))
(test-case "agent policy redirects loop-local POO integer range type construction to a named type binding"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-integer-range-type-construction-loop-performance"
                   "t/scenarios/policy/poo-integer-range-type-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R034"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R034"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/range.ss")
              (check (hash-get details 'kind)
                     => "poo-type-construction-loop-performance")
              (check (hash-get details 'callee) => "IntegerRange")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable POO/MOP type objects to a named binding outside the loop")))
  ))

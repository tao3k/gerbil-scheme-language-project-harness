;;; -*- Gerbil -*-
;;; gerbil scheme harness agent poo policy.

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
(export agent-poo-policy-test)
;; Milliseconds
(def +poo-policy-performance-scenario-max-ms+ 1000)

;; : (-> Milliseconds String )
(def (poo-policy-performance-timing-status total-ms)
  (if (< total-ms +poo-policy-performance-scenario-max-ms+)
    "pass"
    (string-append
     "fail durationMs="
     (number->string total-ms)
     " maxMs="
     (number->string +poo-policy-performance-scenario-max-ms+))))

;; : (-> (List Timing) Boolean )
(def (policy-scenario-timing-steps-measured? timings)
  (cond
   ((null? timings) #t)
   ((and (number? (hash-get (car timings) 'durationMs))
         (>= (hash-get (car timings) 'durationMs) 0))
    (policy-scenario-timing-steps-measured? (cdr timings)))
   (else #f)))

;; PolicyTest
(def agent-poo-policy-test
  (test-suite "gerbil scheme harness agent poo policy"
    (test-case "agent policy rejects direct POO writeenv calls"
          (let* ((root ".run/policy-poo-direct-writeenv")
                 (_ (write-poo-direct-writeenv-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R006" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R006")
            (check (type-finding-path finding) => "src/orders/io.ss")
            (check (type-finding-message finding)
                   => "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first")))
    (test-case "agent policy requires runtime-source witness for POO IO overrides"
          (let* ((root ".run/policy-poo-io-runtime-witness")
                 (_ (write-poo-io-override-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R007" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R007")
            (check (type-finding-path finding) => "src/orders/io.ss")
            (check (type-finding-message finding)
                   => "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified")))
    (test-case "agent policy requires POO method generic and class facts"
          (let* ((root ".run/policy-poo-method-shape")
                 (_ (write-poo-method-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R008" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R008")
            (check (type-finding-path finding) => "src/orders/methods.ss")
            (check (type-finding-message finding)
                   => "POO method order-discount is missing parser-owned defgeneric,defclass-or-defprotocol facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")))
    (test-case "agent policy redirects outer POO constructor slot projection to prototype fixed point"
          (let* ((root ".run/policy-poo-prototype-fixed-point")
                 (_ (write-poo-prototype-fixed-point-drift-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R026" findings))
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
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R026" findings)))
            (check matching => [])))
    (test-case "agent policy allows isolated POO slot boundary reads"
          (let* ((root ".run/policy-poo-prototype-boundary-read")
                 (_ (write-poo-prototype-boundary-read-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R026" findings)))
            (check matching => [])))
    (test-case "agent policy redirects large data-shaped POO object construction to object<-alist"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-construction-performance"
                   "t/scenarios/policy/poo-construction-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R027"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R027"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (hash-get timing 'schemaId)
                     => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
              (check (hash-get timing 'scenarioId)
                     => "poo-construction-performance")
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/profile.ss")
              (check (hash-get details 'kind)
                     => "poo-construction-performance")
              (check (hash-get details 'callee) => ".o")
              (check (hash-get details 'slotSpecCount) => 16)
              (check (hash-get details 'slotSpecThreshold) => 12)
              (check (hash-get details 'preferredConstruction)
                     => "object<-alist for broad mostly-data POO values"))))
    (test-case "agent policy redirects loop-local POO clone overrides out of hot loops"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-clone-override-loop-performance"
                   "t/scenarios/policy/poo-clone-override-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R028"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R028"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/score.ss")
              (check (hash-get details 'kind)
                     => "poo-clone-override-loop-performance")
              (check (hash-get details 'callee) => ".cc")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "accumulate loop state and apply one final .cc; use .put! only for intentional mutable objects"))))
    (test-case "agent policy redirects loop-local POO materialization to a single boundary snapshot"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-materialization-loop-performance"
                   "t/scenarios/policy/poo-materialization-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R029"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R029"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/export.ss")
              (check (hash-get details 'kind)
                     => "poo-materialization-loop-performance")
              (check (hash-get details 'callee) => ".alist/sort")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "materialize or project once outside the loop, or use direct .ref access for specific slots"))))
    (test-case "agent policy redirects loop-local POO slot projection to a boundary snapshot"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-slot-projection-loop-performance"
                   "t/scenarios/policy/poo-slot-projection-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R029"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R029"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/project.ss")
              (check (hash-get details 'kind)
                     => "poo-materialization-loop-performance")
              (check (hash-get details 'callee) => ".refs/slots")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "materialize or project once outside the loop, or use direct .ref access for specific slots"))))
    (test-case "agent policy redirects loop-local POO composition to one boundary object"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-composition-loop-performance"
                   "t/scenarios/policy/poo-composition-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R030"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R030"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/compose.ss")
              (check (hash-get details 'kind)
                     => "poo-composition-loop-performance")
              (check (hash-get details 'callee) => ".mix")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "accumulate scalar loop state and apply one final POO composition outside the loop"))))
    (test-case "agent policy redirects loop-local POO validation to a boundary check"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-validation-loop-performance"
                   "t/scenarios/policy/poo-validation-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R031"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R031"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/validate.ss")
              (check (hash-get details 'kind)
                     => "poo-validation-loop-performance")
              (check (hash-get details 'callee) => "validate")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "validate once outside the loop, then operate on the validated object or scalar fields"))))
    (test-case "agent policy redirects loop-local POO lens modification to a boundary update"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-lens-loop-performance"
                   "t/scenarios/policy/poo-lens-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
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
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/lens.ss")
              (check (hash-get details 'kind)
                     => "poo-lens-loop-performance")
              (check (hash-get details 'callee) => ".call")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "accumulate scalar lens target state and apply one final .cc outside the loop"))))
    (test-case "agent policy redirects loop-local POO object construction to one boundary object"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-object-construction-loop-performance"
                   "t/scenarios/policy/poo-object-construction-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
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
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/construct.ss")
              (check (hash-get details 'kind)
                     => "poo-object-construction-loop-performance")
              (check (hash-get details 'callee) => "object<-hash")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable object construction or accumulate scalar/list/hash state and construct one final POO object"))))
    (test-case "agent policy redirects loop-local POO type construction to a named type binding"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-type-construction-loop-performance"
                   "t/scenarios/policy/poo-type-construction-loop-performance"))
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
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/type.ss")
              (check (hash-get details 'kind)
                     => "poo-type-construction-loop-performance")
              (check (hash-get details 'callee) => "MonomorphicObject")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable POO/MOP type objects to a named binding outside the loop"))))
    (test-case "agent policy redirects loop-local POO debug instrumentation to one setup boundary"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-debug-instrumentation-loop-performance"
                   "t/scenarios/policy/poo-debug-instrumentation-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R035"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R035"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/debug.ss")
              (check (hash-get details 'kind)
                     => "poo-debug-instrumentation-loop-performance")
              (check (hash-get details 'callee) => "trace-poo")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist trace-poo outside the loop and reuse the traced object"))))
    (test-case "agent policy redirects loop-local POO slot-spec mutation to value updates"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-slot-spec-mutation-loop-performance"
                   "t/scenarios/policy/poo-slot-spec-mutation-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R036"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R036"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/shape.ss")
              (check (hash-get details 'kind)
                     => "poo-slot-spec-mutation-loop-performance")
              (check (hash-get details 'callee) => ".def!")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "define slots once at setup; use .put! for intentional value mutation or scalar loop state plus one final object update"))))
    (test-case "agent policy redirects loop-local POO slot predicates to a boundary check"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-slot-predicate-loop-performance"
                   "t/scenarios/policy/poo-slot-predicate-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (total-ms (hash-get timing 'totalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R037"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R037"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (poo-policy-performance-timing-status total-ms)
                     => "pass")
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/predicate.ss")
              (check (hash-get details 'kind)
                     => "poo-slot-predicate-loop-performance")
              (check (hash-get details 'callee) => "o?/slots")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable o?/slots predicate results outside the loop; hoist the predicate closure when only the slot list is stable"))))
    (test-case "agent policy accepts compact POO object construction"
          (let* ((root ".run/policy-poo-construction-performance-compact")
                 (src (string-append root "/src"))
                 (owner (string-append src "/reports")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/reports)\n")
            (write-text
             (string-append owner "/profile.ss")
             ";;; -*- Gerbil -*-\n(import :clan/poo)\n(def (build-report-ref)\n  (.o id: \"orders\" status: \"hot\"))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R027" findings)))
              (check matching => []))))
    (test-case "agent policy requires macro runtime-source witness"
          (let* ((root ".run/policy-macro-runtime-source")
                 (_ (write-macro-runtime-source-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R011" findings))
                 (finding (car matching))
                 (details (type-finding-details finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/macros/core.ss")
            (check (hash-get details 'next)
                   => "search runtime-source macro sugar module-sugar")
            (check (hash-get details 'phase) => "syntax")
            (check (hash-get details 'patternCount) => 0)
            (check (hash-get details 'hygienic) => #t)
            (check (not (not (member "syntax-template-witness"
                                     (hash-get details 'qualityFacets))))
                   => #t)
            (check (hash-get details 'macroFactSource)
                   => "parser-owned macroFacts from native Gerbil syntax extraction")
            (check (hash-get details 'policyBoundary)
                   => "macros are allowed when they stay controlled, source-backed, and explainable")
            (check (hash-get (hash-get details 'runtimeSourceRequirement)
                             'selectorScheme)
                   => "gerbil-runtime-source")
            (check (hash-get (hash-get details 'runtimeSourceRequirement)
                             'selectorFormat)
                   => "gerbil-runtime-source://<source-path>#<symbol>")
            (check (hash-get (hash-get details 'gerbilUtilsSource)
                             'sourcePattern)
                   => "gerbil-utils-controlled-macro-helper")
            (check (not (not (member "gerbil-utils/syntax.ss#syntax-case"
                                     (hash-get (hash-get details 'gerbilUtilsSource)
                                               'sourceOwners))))
                   => #t)
            (check (hash-get details 'agentEscapeConstraint)
                   => "do not weaken macro-governance from a source macro edit; update gerbil.pkg only with a clear explanation and witness")))
    (test-case "agent policy accepts macro runtime-source witness policy"
          (let* ((root ".run/policy-macro-runtime-source-allowed")
                 (_ (write-macro-runtime-source-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R011" findings)))
            (check matching => [])))
    (test-case "agent policy requires declared protocol evidence"
          (let* ((root ".run/policy-protocol-evidence")
                 (_ (write-protocol-evidence-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R012" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/protocol.ss")
            (check (hash-get (type-finding-details finding) 'next)
                   => "search pattern poo protocol")))
    (test-case "agent policy accepts declared protocol evidence"
          (let* ((root ".run/policy-protocol-evidence-positive")
                 (_ (write-protocol-evidence-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R012" findings)))
            (check matching => [])))
    (test-case "agent policy catches downstream POO implementation drift"
          (let* ((root ".run/policy-downstream-poo-agent")
                 (_ (write-downstream-poo-agent-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (vague (filter-rule "GERBIL-SCHEME-AGENT-R004" findings))
                 (direct-writeenv (filter-rule "GERBIL-SCHEME-AGENT-R006" findings))
                 (runtime-witness (filter-rule "GERBIL-SCHEME-AGENT-R007" findings))
                 (method-shape (filter-rule "GERBIL-SCHEME-AGENT-R008" findings))
                 (object-model (filter-rule "GERBIL-SCHEME-AGENT-R010" findings)))
            (check (length vague) => 1)
            (check (length direct-writeenv) => 1)
            (check (length runtime-witness) => 1)
            (check (length method-shape) => 1)
            (check (length object-model) => 1)
            (check (type-finding-path (car vague)) => "src/orders/core.ss")
            (check (type-finding-path (car direct-writeenv)) => "src/orders/io.ss")
            (check (type-finding-path (car runtime-witness)) => "src/orders/io.ss")
            (check (type-finding-path (car method-shape)) => "src/orders/io.ss")
            (check (type-finding-path (car object-model)) => "src/orders/core.ss")
            (check (type-finding-selector (car object-model)) => "src/orders/core.ss:4-4")))
    (test-case "agent policy accepts downstream POO pattern-guided implementation"
          (let* ((root ".run/policy-downstream-poo-agent-positive")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index)))
            (check findings => [])))
    (test-case "gxtest adapter exposes downstream policy report"
          (let* ((root ".run/policy-downstream-poo-agent-gxtest")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (report (project-policy-report root))
                 (agent-repair (hash-get report 'agentRepair)))
            (check (project-policy-status root) => "pass")
            (check (project-policy-findings root) => [])
            (check (hash-get report 'schemaId)
                   => "agent.semantic-protocols.gerbil-scheme-harness-gxtest-report")
            (check (hash-get report 'status) => "pass")
            (check (> (hash-get report 'files) 0) => #t)
            (check (> (hash-get report 'definitions) 0) => #t)
            (check (hash-get report 'findings) => [])
            (check (hash-get agent-repair 'status) => "none")))
    (test-case "agent policy warns on broad runtime imports"
          (let* ((root ".run/policy-explicit-precise-import")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/broad.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :std/srfi/13)\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (write-text (string-append owner "/precise.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import (only-in :std/srfi/13 string-prefix?))\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R018" findings))
                   (finding (car matching)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/broad.ss")
              (check (type-finding-selector finding) => "src/orders/broad.ss:3-3"))))
    (test-case "agent policy rejects duplicate facade exports"
          (let* ((root ".run/policy-export-conflict")
                 (_alpha (write-facade-policy-project
                          root "alpha"
                          ";;; -*- Gerbil -*-\n;;; Alpha facade.\n(export value)\n"
                          ";;; -*- Gerbil -*-\n;;; Alpha core.\n(def value 1)\n"))
                 (_beta (write-facade-policy-project
                         root "beta"
                         ";;; -*- Gerbil -*-\n;;; Beta facade.\n(export value)\n"
                         ";;; -*- Gerbil -*-\n;;; Beta core.\n(def value 2)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R003" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R003")
            (check (type-finding-path finding) => "src/beta/facade.ss")))))

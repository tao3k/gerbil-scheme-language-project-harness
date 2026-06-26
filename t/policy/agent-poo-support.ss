;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent POO policy support.

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
        (only-in :support/time duration-literal->nanos)
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export #t)


;; : (-> TimedPolicyScenarioResult Boolean )
(def (policy-scenario-benchmark-constrained? timing)
  (and (duration-literal->nanos (hash-get timing 'max_total))
       (equal? (hash-get timing 'performanceStatus) "pass")))

;; : (-> TimedPolicyScenarioResult Boolean )
(def (policy-scenario-benchmark-targeted? timing)
  (let* ((observed-ns
          (duration-literal->nanos (hash-get timing 'observed_total)))
         (target-ns
          (duration-literal->nanos (hash-get timing 'target_total)))
         (max-ns
          (duration-literal->nanos (hash-get timing 'max_total)))
         (regression-budget-ns
          (duration-literal->nanos (hash-get timing 'regression_budget))))
    (and observed-ns
         target-ns
         max-ns
         regression-budget-ns
         (<= observed-ns target-ns)
         (< target-ns max-ns)
         (= max-ns (+ observed-ns regression-budget-ns)))))

;; : (-> MaybeNumber String )
(def (poo-policy-performance-timing-status total-ms)
  (if (and (number? total-ms) (>= total-ms 0))
    "pass"
    "fail"))

;; : (-> (List Timing) Boolean )
(def (policy-scenario-timing-steps-measured? timings)
  (cond
   ((null? timings) #t)
   ((and (number? (hash-get (car timings) 'durationMs))
         (>= (hash-get (car timings) 'durationMs) 0))
    (policy-scenario-timing-steps-measured? (cdr timings)))
   (else #f)))

(def +poo-performance-scenario-ids+
  '("poo-clone-override-loop-performance"
    "poo-composition-loop-performance"
    "poo-construction-performance"
    "poo-debug-instrumentation-loop-performance"
    "poo-fq-type-construction-loop-performance"
    "poo-function-type-construction-loop-performance"
    "poo-integer-range-type-construction-loop-performance"
    "poo-lens-loop-performance"
    "poo-materialization-loop-performance"
    "poo-object-construction-loop-performance"
    "poo-object-iteration-loop-performance"
    "poo-real-dashboard-workflow-performance"
    "poo-slot-predicate-loop-performance"
    "poo-slot-projection-loop-performance"
    "poo-slot-spec-mutation-loop-performance"
    "poo-type-construction-loop-performance"
    "poo-validation-loop-performance"
    "poo-z-type-construction-loop-performance"))

(def +poo-real-dashboard-workflow-rule-ids+
  '("GERBIL-SCHEME-AGENT-R028"
    "GERBIL-SCHEME-AGENT-R029"
    "GERBIL-SCHEME-AGENT-R030"
    "GERBIL-SCHEME-AGENT-R031"
    "GERBIL-SCHEME-AGENT-R033"
    "GERBIL-SCHEME-AGENT-R035"
    "GERBIL-SCHEME-AGENT-R037"))

;; : (-> PolicyScenarioResult Symbol (List String) (List TypeFinding) )
(def (policy-scenario-findings/rules result phase rule-ids)
  (apply append
         (map (lambda (rule-id)
                (policy-scenario-findings result phase rule-id))
              rule-ids)))

;; : (-> String (List TypeFinding) Boolean )
(def (policy-rule-present? rule-id findings)
  (if (member rule-id (map type-finding-rule-id findings)) #t #f))

;; : (-> String String )
(def (poo-performance-scenario-benchmark-path scenario-id)
  (string-append "t/scenarios/policy/" scenario-id "/benchmark.ss"))

;; : (-> (List String) (List String) )
(def (missing-poo-performance-scenario-benchmarks scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((file-exists? (poo-performance-scenario-benchmark-path (car scenario-ids)))
    (missing-poo-performance-scenario-benchmarks (cdr scenario-ids)))
   (else
    (cons (poo-performance-scenario-benchmark-path (car scenario-ids))
          (missing-poo-performance-scenario-benchmarks (cdr scenario-ids))))))

;; : (-> String BenchmarkContract )
(def (poo-performance-scenario-benchmark-contract scenario-id)
  (policy-scenario-benchmark-contract
   (make-policy-scenario
    scenario-id
    (string-append "t/scenarios/policy/" scenario-id))))

;; : (-> BenchmarkContract Boolean )
(def (poo-performance-scenario-hot-path-exemption-complete? contract)
  (and (hash-get contract 'hotPathExemption)
       (pair? (hash-get contract 'hotPathEvidence))
       (hash-get contract 'styleRewriteBoundary)))

;; : (-> (List String) (List String) )
(def (poo-performance-scenarios-missing-hot-path-exemptions scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-hot-path-exemption-complete?
     (poo-performance-scenario-benchmark-contract (car scenario-ids)))
    (poo-performance-scenarios-missing-hot-path-exemptions
     (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-hot-path-exemptions
           (cdr scenario-ids))))))

;; PolicyTest

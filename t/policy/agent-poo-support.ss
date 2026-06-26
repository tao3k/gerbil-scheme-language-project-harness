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
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export #t)


;; : (-> TimedPolicyScenarioResult Boolean )
(def (policy-scenario-benchmark-constrained? timing)
  (and (number? (hash-get timing 'maxTotalMs))
       (equal? (hash-get timing 'performanceStatus) "pass")))

;; : (-> TimedPolicyScenarioResult Boolean )
(def (policy-scenario-benchmark-targeted? timing)
  (let* ((observed-ms (hash-get timing 'observedTotalMs))
         (target-ms (hash-get timing 'targetTotalMs))
         (max-ms (hash-get timing 'maxTotalMs))
         (regression-budget-ms (hash-get timing 'regressionBudgetMs)))
    (and (number? observed-ms)
         (number? target-ms)
         (number? max-ms)
         (number? regression-budget-ms)
         (<= observed-ms target-ms)
         (< target-ms max-ms)
         (= max-ms (+ observed-ms regression-budget-ms)))))

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

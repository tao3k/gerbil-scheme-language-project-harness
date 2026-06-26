;;; -*- Gerbil -*-
;;; Boundary: reusable benchmark fixtures and performance gate receipts.

(import :support/time
        (only-in :std/sugar andmap ormap))

(export benchmark-default-max-total
        benchmark-default-max-collect-ms
        benchmark-default-max-parse-ms
        benchmark-default-max-file-ms
        benchmark-default-max-phase-ms
        benchmark-default-observed-total
        benchmark-default-target-total
        benchmark-default-regression-budget
        benchmark-default-max-rss-mb
        benchmark-default-memory-metric
        benchmark-default-memory-unit
        benchmark-fixture-required-keys
        make-benchmark-fixture
        benchmark-fixture-ref
        benchmark-fixture-missing-keys
        benchmark-fixture-memory-contract-pass?
        benchmark-fixture-observed-timings-contract-pass?
        benchmark-fixture-integration-scope?
        benchmark-fixture-timing-class-contract-pass?
        benchmark-fixture-contract-pass?
        benchmark-elapsed-micros
        benchmark-elapsed-ms
        benchmark-best-elapsed-micros
        benchmark-best-elapsed-ms
        benchmark-run
        benchmark-receipt-pass?)

;; benchmark-default-max-total
;;   : DurationLiteral
;;   | doc m%
;;       Default wall-clock budget for policy scenario benchmark receipts.
;;     %
(def benchmark-default-max-total '100ms)
;; : Integer
(def benchmark-default-max-collect-ms 25)
;; : Integer
(def benchmark-default-max-parse-ms 15)
;; : Integer
(def benchmark-default-max-file-ms 5)
;; : Integer
(def benchmark-default-max-phase-ms 5)
;; : DurationLiteral
(def benchmark-default-observed-total '10ms)
;; : DurationLiteral
(def benchmark-default-target-total '25ms)
;; : DurationLiteral
(def benchmark-default-regression-budget '15ms)
;; : Integer
(def benchmark-default-max-rss-mb 512)
;; : DurationLiteral
(def benchmark-hot-target-total '25ms)
;; : DurationLiteral
(def benchmark-hot-max-total '100ms)
;; : DurationLiteral
(def benchmark-integration-max-total '1s)
;; : Symbol
(def benchmark-default-memory-metric 'resident-set-size)
;; : String
(def benchmark-default-memory-unit "MB")

;; benchmark-fixture-required-keys
;;   : (List Symbol)
;;   | doc m%
;;       Minimum fixture contract shared by scenario files and runtime gates.
;;     %
(def benchmark-fixture-required-keys
  '(max_total
    maxCollectMs
    maxParseMs
    maxFileMs
    maxPhaseMs
    observed_total
    target_total
    regression_budget
    observedTimings
    targetRationale
    maxRssMb
    memoryMetric
    memoryUnit
    iterations
    unit
    rule
    feature
    optimizationFocus
    inputShape
    expectedRepair
    measurementPhases
    tags))

;; : (List Symbol)
(def +benchmark-positive-duration-fields+
  '(max_total target_total))

;; : (List Symbol)
(def +benchmark-non-negative-duration-fields+
  '(observed_total regression_budget))

;; : (List Symbol)
(def +benchmark-positive-number-fields+
  '(maxCollectMs maxParseMs maxFileMs maxPhaseMs))

;; : (List Symbol)
(def +benchmark-positive-integer-fields+
  '(iterations))

;; +benchmark-integration-tags+
;;   : (List String)
;;   | doc m%
;;       Tags for benchmarks that intentionally include source collection,
;;       gxtest import closure, subprocess, cache, or launcher boundaries.
;;     %
(def +benchmark-integration-tags+
  '("integration" "import-closure" "gxtest" "downstream"
    "cold-path" "cache" "launcher" "subprocess"))

;; make-benchmark-fixture
;;   : (-> Symbol Symbol String String String (List Symbol) Alist)
;;   | doc m%
;;       Build the benchmark fixture alist consumed by scenario gates.
;;     %
(def (make-benchmark-fixture rule feature optimization-focus
                             input-shape expected-repair tags)
  (list (cons 'max_total benchmark-default-max-total)
        (cons 'maxCollectMs benchmark-default-max-collect-ms)
        (cons 'maxParseMs benchmark-default-max-parse-ms)
        (cons 'maxFileMs benchmark-default-max-file-ms)
        (cons 'maxPhaseMs benchmark-default-max-phase-ms)
        (cons 'observed_total benchmark-default-observed-total)
        (cons 'target_total benchmark-default-target-total)
        (cons 'regression_budget benchmark-default-regression-budget)
        (cons 'observedTimings
              `(((name . measure-best)
                 (durationMs . 10))))
        (cons 'targetRationale
              "default generated benchmark fixture target")
        (cons 'maxRssMb benchmark-default-max-rss-mb)
        (cons 'memoryMetric benchmark-default-memory-metric)
        (cons 'memoryUnit benchmark-default-memory-unit)
        (cons 'iterations 3)
        (cons 'unit "ms")
        (cons 'rule rule)
        (cons 'feature feature)
        (cons 'optimizationFocus optimization-focus)
        (cons 'inputShape input-shape)
        (cons 'expectedRepair expected-repair)
        (cons 'measurementPhases
              '(prepare-fixture measure-best assert-time-gate assert-memory-gate))
        (cons 'tags tags)))

;; benchmark-fixture-ref
;;   : (-> Alist Symbol Value)
;;   | doc m%
;;       Read required fixture metadata and fail loudly when a field is missing.
;;     %
(def (benchmark-fixture-ref fixture key)
  (let (entry (assoc key fixture))
    (if entry
      (cdr entry)
      (error "missing benchmark fixture key" key))))

;; benchmark-fixture-missing-keys
;;   : (-> Alist (List Symbol))
;;   | doc m%
;;       Return required benchmark fixture keys that are absent from an alist.
;;     %
(def (benchmark-fixture-missing-keys fixture)
  (filter (lambda (key) (not (assoc key fixture)))
          benchmark-fixture-required-keys))

;; benchmark-fixture-phase-present?
;;   : (-> (List Value) Symbol Boolean)
;;   | doc m%
;;       Return `#t` when a phase appears either as its symbol or string form.
;;
;;       Scenario fixtures sometimes cross JSON boundaries, so this predicate
;;       accepts both representations without branching at each call site.
;;
;;       # Examples
;;
;;       ```scheme
;;       (benchmark-fixture-phase-present? '(prepare-fixture) 'prepare-fixture)
;;       ;; => #t
;;       ```
;;     %
(def (benchmark-fixture-phase-present? phases phase)
  (ormap (lambda (candidate) (member candidate phases))
         [phase (symbol->string phase)]))

;; : (-> Number Boolean)
(def (benchmark-positive-number? value)
  (and (number? value) (> value 0)))

;; : (-> Number Boolean)
(def (benchmark-non-negative-number? value)
  (and (number? value) (>= value 0)))

;; : (-> Integer Boolean)
(def (benchmark-positive-integer? value)
  (and (integer? value) (> value 0)))

;; : (-> Integer Boolean)
(def (benchmark-non-negative-integer? value)
  (and (integer? value) (>= value 0)))

;; : (-> Alist Symbol Boolean)
(def (benchmark-fixture-positive-number-field-pass? fixture key)
  (benchmark-positive-number? (benchmark-fixture-ref fixture key)))

;; : (-> Alist Symbol (U Integer False))
(def (benchmark-fixture-duration-field-nanos fixture key)
  (duration-literal->nanos (benchmark-fixture-ref fixture key)))

;; : (-> Alist Symbol Boolean)
(def (benchmark-fixture-positive-duration-field-pass? fixture key)
  (let (nanos (benchmark-fixture-duration-field-nanos fixture key))
    (and nanos (> nanos 0))))

;; : (-> Alist Symbol Boolean)
(def (benchmark-fixture-non-negative-duration-field-pass? fixture key)
  (let (nanos (benchmark-fixture-duration-field-nanos fixture key))
    (and nanos (>= nanos 0))))

;; : (-> Alist Boolean)
(def (benchmark-fixture-positive-duration-fields-pass? fixture)
  (andmap (lambda (key)
            (benchmark-fixture-positive-duration-field-pass? fixture key))
          +benchmark-positive-duration-fields+))

;; : (-> Alist Boolean)
(def (benchmark-fixture-non-negative-duration-fields-pass? fixture)
  (andmap (lambda (key)
            (benchmark-fixture-non-negative-duration-field-pass? fixture key))
          +benchmark-non-negative-duration-fields+))

;; : (-> Alist Boolean)
(def (benchmark-fixture-positive-number-fields-pass? fixture)
  (andmap (lambda (key)
            (benchmark-fixture-positive-number-field-pass? fixture key))
          +benchmark-positive-number-fields+))

;; : (-> Alist Symbol Boolean)
(def (benchmark-fixture-positive-integer-field-pass? fixture key)
  (benchmark-positive-integer? (benchmark-fixture-ref fixture key)))

;; : (-> Alist Boolean)
(def (benchmark-fixture-positive-integer-fields-pass? fixture)
  (andmap (lambda (key)
            (benchmark-fixture-positive-integer-field-pass? fixture key))
          +benchmark-positive-integer-fields+))

;; : (-> Alist Boolean)
(def (benchmark-fixture-unit-contract-pass? fixture)
  (equal? (benchmark-fixture-ref fixture 'unit) "ms"))

;; benchmark-fixture-memory-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate the reusable RSS budget fields required by benchmark fixtures.
;;     %
(def (benchmark-fixture-memory-contract-pass? fixture)
  (let ((max-rss-entry (assoc 'maxRssMb fixture))
        (memory-metric-entry (assoc 'memoryMetric fixture))
        (memory-unit-entry (assoc 'memoryUnit fixture))
        (measurement-phases-entry (assoc 'measurementPhases fixture)))
    (and max-rss-entry
         memory-metric-entry
         memory-unit-entry
         measurement-phases-entry
         (let ((max-rss-mb (cdr max-rss-entry))
               (memory-metric (cdr memory-metric-entry))
               (memory-unit (cdr memory-unit-entry))
               (measurement-phases (cdr measurement-phases-entry)))
           (and (benchmark-positive-integer? max-rss-mb)
                (eq? memory-metric benchmark-default-memory-metric)
                (equal? memory-unit benchmark-default-memory-unit)
                (not (not (benchmark-fixture-phase-present?
                           measurement-phases
                           'assert-memory-gate))))))))

;; benchmark-fixture-observed-timings-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate observed timing baseline fields carried by benchmark fixtures.
;;     %
(def (benchmark-fixture-observed-timings-contract-pass? fixture)
  (let ((observed-total-entry (assoc 'observed_total fixture))
        (target-total-entry (assoc 'target_total fixture))
        (regression-budget-entry (assoc 'regression_budget fixture))
        (observed-timings-entry (assoc 'observedTimings fixture))
        (target-rationale-entry (assoc 'targetRationale fixture)))
    (and observed-total-entry
         target-total-entry
         regression-budget-entry
         observed-timings-entry
         target-rationale-entry
         (let ((observed-total-ns
                (duration-literal->nanos (cdr observed-total-entry)))
               (target-total-ns
                (duration-literal->nanos (cdr target-total-entry)))
               (regression-budget-ns
                (duration-literal->nanos (cdr regression-budget-entry)))
               (observed-timings (cdr observed-timings-entry))
               (target-rationale (cdr target-rationale-entry)))
           (and observed-total-ns
                target-total-ns
                regression-budget-ns
                (>= observed-total-ns 0)
                (> target-total-ns 0)
                (>= regression-budget-ns 0)
                (string? target-rationale)
                (list? observed-timings)
                (not (null? observed-timings))
                (andmap benchmark-observed-timing-contract-pass?
                        observed-timings))))))

;; : (-> Alist Boolean)
(def (benchmark-observed-timing-contract-pass? timing)
  (and (list? timing)
       (let ((name-entry (assoc 'name timing))
             (duration-entry (assoc 'durationMs timing)))
         (and name-entry
              duration-entry
              (let ((name (cdr name-entry))
                    (duration-ms (cdr duration-entry)))
                (and (or (symbol? name) (string? name))
                     (benchmark-non-negative-number? duration-ms)))))))

;; benchmark-tag-equal?
;;   : (-> BenchmarkTagCandidate String Boolean)
;;   | type BenchmarkTagCandidate = (U Symbol String)
;;   | doc m%
;;       Compare a fixture tag carried as a Scheme symbol or JSON string with
;;       the normalized integration tag name.
;;     %
(def (benchmark-tag-equal? candidate tag)
  (cond
   ((symbol? candidate) (equal? (symbol->string candidate) tag))
   ((string? candidate) (equal? candidate tag))
   (else #f)))

;; : (-> Alist String Boolean)
(def (benchmark-fixture-tag? fixture tag)
  (ormap (lambda (candidate)
           (benchmark-tag-equal? candidate tag))
         (benchmark-fixture-ref fixture 'tags)))

;; : (-> Alist Boolean)
(def (benchmark-fixture-integration-scope? fixture)
  (ormap (lambda (tag)
           (benchmark-fixture-tag? fixture tag))
         +benchmark-integration-tags+))

;; : (-> Alist Boolean)
(def (benchmark-fixture-hot-timing-pass? fixture)
  (let ((max-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'max_total))
        (target-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'target_total))
        (observed-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'observed_total))
        (hot-max-total-ns (duration-literal->nanos benchmark-hot-max-total))
        (hot-target-total-ns
         (duration-literal->nanos benchmark-hot-target-total)))
    (and max-total-ns
         target-total-ns
         observed-total-ns
         (<= max-total-ns hot-max-total-ns)
         (<= target-total-ns hot-target-total-ns)
         (<= observed-total-ns target-total-ns))))

;; : (-> Alist Boolean)
(def (benchmark-fixture-integration-timing-pass? fixture)
  (let ((max-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'max_total))
        (target-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'target_total))
        (observed-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'observed_total))
        (integration-max-total-ns
         (duration-literal->nanos benchmark-integration-max-total)))
    (and max-total-ns
         target-total-ns
         observed-total-ns
         (< max-total-ns integration-max-total-ns)
         (< target-total-ns integration-max-total-ns)
         (< observed-total-ns integration-max-total-ns)
         (<= observed-total-ns target-total-ns))))

;;; Timing class contract:
;;; - Hot policy scenarios are the default and must keep a tight millisecond
;;;   budget; this is where Gerbil/Gambit language idioms should pay off.
;;; - Integration scenarios may include gxtest import closure, launcher, cache,
;;;   or subprocess overhead, but must say so through tags and stay subsecond.
;; : (-> Alist Boolean)
(def (benchmark-fixture-timing-class-contract-pass? fixture)
  (if (benchmark-fixture-integration-scope? fixture)
    (benchmark-fixture-integration-timing-pass? fixture)
    (benchmark-fixture-hot-timing-pass? fixture)))

;; benchmark-fixture-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate the shared fixture contract without running the benchmark.
;;     %
(def (benchmark-fixture-contract-pass? fixture)
  (and (null? (benchmark-fixture-missing-keys fixture))
       (benchmark-fixture-positive-duration-fields-pass? fixture)
       (benchmark-fixture-non-negative-duration-fields-pass? fixture)
       (benchmark-fixture-positive-number-fields-pass? fixture)
       (benchmark-fixture-positive-integer-fields-pass? fixture)
       (benchmark-fixture-unit-contract-pass? fixture)
       (benchmark-fixture-observed-timings-contract-pass? fixture)
       (benchmark-fixture-memory-contract-pass? fixture)
       (benchmark-fixture-timing-class-contract-pass? fixture)))

;; benchmark-elapsed-micros
;;   : (-> (-> Value) Integer)
;;   | doc m%
;;       Measure one benchmark thunk with microsecond precision.
;;     %
(def (benchmark-elapsed-micros thunk)
  (let (start-micros (monotonic-micros))
    (thunk)
    (duration-micros start-micros (monotonic-micros))))

;; benchmark-elapsed-ms
;;   : (-> (-> Value) Number)
;;   | doc m%
;;       Return elapsed milliseconds while preserving sub-millisecond observations.
;;     %
(def (benchmark-elapsed-ms thunk)
  (/ (benchmark-elapsed-micros thunk) 1000.0))

;; benchmark-best-elapsed-micros
;;   : (-> Integer (-> Value) Integer)
;;   | doc m%
;;       Return the best elapsed microseconds across positive attempts.
;;     %
(def (benchmark-best-elapsed-micros attempts thunk)
  (if (<= attempts 0)
    (error "benchmark attempts must be positive" attempts)
    (apply min
           (map (lambda (_) (benchmark-elapsed-micros thunk))
                (iota attempts)))))

;; benchmark-best-elapsed-ms
;;   : (-> Integer (-> Value) Number)
;;   | doc m%
;;       Return the best elapsed milliseconds across positive attempts.
;;     %
(def (benchmark-best-elapsed-ms attempts thunk)
  (/ (benchmark-best-elapsed-micros attempts thunk) 1000.0))

;; benchmark-run
;;   : (-> Alist (-> Value) Alist)
;;   | doc m%
;;       Run a fixture benchmark and return the complete receipt expected by tests.
;;     %
(def (benchmark-run fixture thunk)
  (let* ((elapsed-micros
          (benchmark-best-elapsed-micros
           (benchmark-fixture-ref fixture 'iterations)
           thunk))
         (elapsed-nanos (micros->nanos elapsed-micros))
         (elapsed-ms (/ elapsed-micros 1000.0))
         (max-total
          (benchmark-fixture-ref fixture 'max_total))
         (max-total-ns
          (or (duration-literal->nanos max-total)
              (error "invalid benchmark duration literal"
                     'max_total
                     max-total))))
    (list (cons 'rule (benchmark-fixture-ref fixture 'rule))
          (cons 'feature (benchmark-fixture-ref fixture 'feature))
          (cons 'optimizationFocus
                (benchmark-fixture-ref fixture 'optimizationFocus))
          (cons 'inputShape (benchmark-fixture-ref fixture 'inputShape))
          (cons 'expectedRepair
                (benchmark-fixture-ref fixture 'expectedRepair))
          (cons 'elapsedMs elapsed-ms)
          (cons 'elapsedMicros elapsed-micros)
          (cons 'elapsedNs elapsed-nanos)
          (cons 'max_total max-total)
          (cons 'observed_total
                (benchmark-fixture-ref fixture 'observed_total))
          (cons 'target_total
                (benchmark-fixture-ref fixture 'target_total))
          (cons 'regression_budget
                (benchmark-fixture-ref fixture 'regression_budget))
          (cons 'observedTimings
                (benchmark-fixture-ref fixture 'observedTimings))
          (cons 'targetRationale
                (benchmark-fixture-ref fixture 'targetRationale))
          (cons 'maxCollectMs (benchmark-fixture-ref fixture 'maxCollectMs))
          (cons 'maxParseMs (benchmark-fixture-ref fixture 'maxParseMs))
          (cons 'maxFileMs (benchmark-fixture-ref fixture 'maxFileMs))
          (cons 'maxPhaseMs (benchmark-fixture-ref fixture 'maxPhaseMs))
          (cons 'maxRssMb (benchmark-fixture-ref fixture 'maxRssMb))
          (cons 'memoryMetric (benchmark-fixture-ref fixture 'memoryMetric))
          (cons 'memoryUnit (benchmark-fixture-ref fixture 'memoryUnit))
          (cons 'status (if (< elapsed-nanos max-total-ns) 'pass 'fail)))))

;; benchmark-receipt-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Predicate used by scenario tests to keep benchmark pass/fail checks uniform.
;;     %
(def (benchmark-receipt-pass? receipt)
  (eq? (benchmark-fixture-ref receipt 'status) 'pass))

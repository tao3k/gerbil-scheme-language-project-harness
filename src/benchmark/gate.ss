;;; -*- Gerbil -*-
;;; Boundary: reusable benchmark fixtures and performance gate receipts.

(import :support/time
        (only-in :std/sugar andmap ormap))

(export benchmark-default-max-total-ms
        benchmark-default-max-collect-ms
        benchmark-default-max-parse-ms
        benchmark-default-max-file-ms
        benchmark-default-max-phase-ms
        benchmark-default-max-rss-mb
        benchmark-default-memory-metric
        benchmark-default-memory-unit
        benchmark-fixture-required-keys
        make-benchmark-fixture
        benchmark-fixture-ref
        benchmark-fixture-missing-keys
        benchmark-fixture-memory-contract-pass?
        benchmark-fixture-observed-timings-contract-pass?
        benchmark-fixture-contract-pass?
        benchmark-elapsed-ms
        benchmark-best-elapsed-ms
        benchmark-run
        benchmark-receipt-pass?)

;; benchmark-default-max-total-ms
;;   : Integer
;;   | doc m%
;;       Default wall-clock budget for policy scenario benchmark receipts.
;;     %
(def benchmark-default-max-total-ms 1000)
;; : Integer
(def benchmark-default-max-collect-ms 1000)
;; : Integer
(def benchmark-default-max-parse-ms 750)
;; : Integer
(def benchmark-default-max-file-ms 250)
;; : Integer
(def benchmark-default-max-phase-ms 100)
;; : Integer
(def benchmark-default-max-rss-mb 512)
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
  '(maxTotalMs
    maxCollectMs
    maxParseMs
    maxFileMs
    maxPhaseMs
    observedTotalMs
    targetTotalMs
    regressionBudgetMs
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
  '(maxTotalMs maxCollectMs maxParseMs maxFileMs maxPhaseMs))

;; : (List Symbol)
(def +benchmark-positive-integer-fields+
  '(iterations))

;; make-benchmark-fixture
;;   : (-> Symbol Symbol String String String (List Symbol) Alist)
;;   | doc m%
;;       Build the benchmark fixture alist consumed by scenario gates.
;;     %
(def (make-benchmark-fixture rule feature optimization-focus
                             input-shape expected-repair tags)
  (list (cons 'maxTotalMs benchmark-default-max-total-ms)
        (cons 'maxCollectMs benchmark-default-max-collect-ms)
        (cons 'maxParseMs benchmark-default-max-parse-ms)
        (cons 'maxFileMs benchmark-default-max-file-ms)
        (cons 'maxPhaseMs benchmark-default-max-phase-ms)
        (cons 'observedTotalMs benchmark-default-max-total-ms)
        (cons 'targetTotalMs benchmark-default-max-total-ms)
        (cons 'regressionBudgetMs 0)
        (cons 'observedTimings
              '(((name . measure-best) (durationMs . 1000))))
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

;; : (-> Alist Boolean)
(def (benchmark-fixture-positive-duration-fields-pass? fixture)
  (andmap (lambda (key)
            (benchmark-fixture-positive-number-field-pass? fixture key))
          +benchmark-positive-duration-fields+))

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
  (let ((observed-total-entry (assoc 'observedTotalMs fixture))
        (target-total-entry (assoc 'targetTotalMs fixture))
        (regression-budget-entry (assoc 'regressionBudgetMs fixture))
        (observed-timings-entry (assoc 'observedTimings fixture))
        (target-rationale-entry (assoc 'targetRationale fixture)))
    (and observed-total-entry
         target-total-entry
         regression-budget-entry
         observed-timings-entry
         target-rationale-entry
         (let ((observed-total-ms (cdr observed-total-entry))
               (target-total-ms (cdr target-total-entry))
               (regression-budget-ms (cdr regression-budget-entry))
               (observed-timings (cdr observed-timings-entry))
               (target-rationale (cdr target-rationale-entry)))
           (and (benchmark-non-negative-number? observed-total-ms)
                (benchmark-positive-number? target-total-ms)
                (benchmark-non-negative-number? regression-budget-ms)
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

;; benchmark-fixture-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate the shared fixture contract without running the benchmark.
;;     %
(def (benchmark-fixture-contract-pass? fixture)
  (and (null? (benchmark-fixture-missing-keys fixture))
       (benchmark-fixture-positive-duration-fields-pass? fixture)
       (benchmark-fixture-positive-integer-fields-pass? fixture)
       (benchmark-fixture-unit-contract-pass? fixture)
       (benchmark-fixture-observed-timings-contract-pass? fixture)
       (benchmark-fixture-memory-contract-pass? fixture)))

;; benchmark-elapsed-ms
;;   : (-> (-> Value) Integer)
;;   | doc m%
;;       Measure one benchmark thunk with the monotonic clock boundary hidden here.
;;     %
(def (benchmark-elapsed-ms thunk)
  (let (start-ms (monotonic-ms))
    (thunk)
    (duration-ms start-ms (monotonic-ms))))

;; benchmark-best-elapsed-ms
;;   : (-> Integer (-> Value) Integer)
;;   | doc m%
;;       Return the best elapsed time across positive attempts without hand-written recursion.
;;     %
(def (benchmark-best-elapsed-ms attempts thunk)
  (if (<= attempts 0)
    (error "benchmark attempts must be positive" attempts)
    (apply min
           (map (lambda (_) (benchmark-elapsed-ms thunk))
                (iota attempts)))))

;; benchmark-run
;;   : (-> Alist (-> Value) Alist)
;;   | doc m%
;;       Run a fixture benchmark and return the complete receipt expected by tests.
;;     %
(def (benchmark-run fixture thunk)
  (let* ((elapsed-ms
          (benchmark-best-elapsed-ms
           (benchmark-fixture-ref fixture 'iterations)
           thunk))
         (max-total-ms
          (benchmark-fixture-ref fixture 'maxTotalMs)))
    (list (cons 'rule (benchmark-fixture-ref fixture 'rule))
          (cons 'feature (benchmark-fixture-ref fixture 'feature))
          (cons 'optimizationFocus
                (benchmark-fixture-ref fixture 'optimizationFocus))
          (cons 'inputShape (benchmark-fixture-ref fixture 'inputShape))
          (cons 'expectedRepair
                (benchmark-fixture-ref fixture 'expectedRepair))
          (cons 'elapsedMs elapsed-ms)
          (cons 'maxTotalMs max-total-ms)
          (cons 'observedTotalMs
                (benchmark-fixture-ref fixture 'observedTotalMs))
          (cons 'targetTotalMs
                (benchmark-fixture-ref fixture 'targetTotalMs))
          (cons 'regressionBudgetMs
                (benchmark-fixture-ref fixture 'regressionBudgetMs))
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
          (cons 'status (if (< elapsed-ms max-total-ms) 'pass 'fail)))))

;; benchmark-receipt-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Predicate used by scenario tests to keep benchmark pass/fail checks uniform.
;;     %
(def (benchmark-receipt-pass? receipt)
  (eq? (benchmark-fixture-ref receipt 'status) 'pass))

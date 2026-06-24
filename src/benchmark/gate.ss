;;; -*- Gerbil -*-
;;; Boundary: reusable benchmark fixtures and performance gate receipts.

(import :support/time)

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
;; Integer
(def benchmark-default-max-collect-ms 1000)
;; Integer
(def benchmark-default-max-parse-ms 750)
;; Integer
(def benchmark-default-max-file-ms 250)
;; Integer
(def benchmark-default-max-phase-ms 100)
;; Integer
(def benchmark-default-max-rss-mb 512)
;; Symbol
(def benchmark-default-memory-metric 'resident-set-size)
;; String
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

;; : (-> (List Value) Symbol Boolean)
(def (benchmark-fixture-phase-present? phases phase)
  (or (member phase phases)
      (member (symbol->string phase) phases)))

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
           (and (integer? max-rss-mb)
                (> max-rss-mb 0)
                (eq? memory-metric benchmark-default-memory-metric)
                (equal? memory-unit benchmark-default-memory-unit)
                (not (not (benchmark-fixture-phase-present?
                           measurement-phases
                           'assert-memory-gate))))))))

;; benchmark-fixture-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate the shared fixture contract without running the benchmark.
;;     %
(def (benchmark-fixture-contract-pass? fixture)
  (and (null? (benchmark-fixture-missing-keys fixture))
       (let ((max-total-ms (benchmark-fixture-ref fixture 'maxTotalMs))
             (max-collect-ms (benchmark-fixture-ref fixture 'maxCollectMs))
             (max-parse-ms (benchmark-fixture-ref fixture 'maxParseMs))
             (max-file-ms (benchmark-fixture-ref fixture 'maxFileMs))
             (max-phase-ms (benchmark-fixture-ref fixture 'maxPhaseMs))
             (iterations (benchmark-fixture-ref fixture 'iterations))
             (unit (benchmark-fixture-ref fixture 'unit)))
         (and (integer? max-total-ms)
              (> max-total-ms 0)
              (integer? max-collect-ms)
              (> max-collect-ms 0)
              (integer? max-parse-ms)
              (> max-parse-ms 0)
              (integer? max-file-ms)
              (> max-file-ms 0)
              (integer? max-phase-ms)
              (> max-phase-ms 0)
              (integer? iterations)
              (> iterations 0)
              (equal? unit "ms")
              (benchmark-fixture-memory-contract-pass? fixture)))))

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

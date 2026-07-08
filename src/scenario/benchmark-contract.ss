;;; -*- Gerbil -*-
;;; Lightweight benchmark contract normalization for policy scenarios.

(import :gerbil/gambit
        (only-in :std/sugar hash hash-put!)
        :support/time)

(export scenario-benchmark-contract/path
        scenario-benchmark-datum->contract
        scenario-benchmark-max-total)

;; : (List BenchmarkContractKey)
(def +scenario-benchmark-required-duration-fields+
  '(max_total
    observed_total
    target_total
    regression_budget))

;; : (List BenchmarkContractKey)
(def +scenario-benchmark-required-value-fields+
  '(maxCollectMs
    observedCollectMs
    maxParseMs
    observedParseMs
    maxFileMs
    observedFileMs
    maxPhaseMs
    observedPhaseMs
    observedTimings
    targetRationale))

;; : (List (Cons BenchmarkContractKey BenchmarkContractValue))
(def +scenario-benchmark-default-fields+
  '((expected_over_input_note . #f)
    (iterations . 1)
    (unit . "ms")
    (purpose . "scenario timing")
    (feature . "policy-scenario")
    (rule . #f)
    (optimizationFocus . #f)
    (inputShape . #f)
    (expectedOutcome . #f)
    (nativePooPrimary . #f)
    (adapterBoundary . #f)
    (expectedReferencePattern . #f)
    (expectedReferenceExamples . ())
    (expectedQualitySignals . ())
    (learnedStyleSources . ())
    (antiAiScaffoldIntent . #f)
    (scenarioQualityAxes . ())
    (hotPathExemption . #f)
    (hotPathEvidence . ())
    (styleRewriteBoundary . #f)
    (maxRssMb . 512)
    (memoryMetric . resident-set-size)
    (memoryUnit . "MB")
    (measurementPhases . ("collect-before"
                          "collect-after"
                          "policy-before"
                          "policy-after"))
    (tags . ())))

;;; Fixture benchmark contract:
;;; - A scenario must carry benchmark.ss beside input/ and expected/.
;;; - The file is data, not code: an alist such as ((max_total . 1s)).
;;; - This module avoids loading parser and policy facades for metadata sweeps.
;; : (-> Id Path BenchmarkContract )
(def (scenario-benchmark-contract/path scenario-id path)
  (if (file-exists? path)
    (scenario-benchmark-datum->contract
     (call-with-input-file path read))
    (error "policy scenario requires benchmark.ss" scenario-id path)))

;;; Contract normalization boundary:
;;; - Keep fixture syntax small and stable.
;;; - Timed runners receive hash data so tests and future JSON packets do not
;;;   depend on alist shape.
;;; - Baseline, target, and regression budget are required so performance
;;;   guidance exposes optimization headroom instead of only a loose timeout.
;; : (-> BenchmarkContractDatum BenchmarkContract )
(def (scenario-benchmark-datum->contract datum)
  (let (contract
        (hash (schemaId "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
              (schemaVersion "2")))
    (scenario-benchmark-put-fields!
     contract
     datum
     +scenario-benchmark-required-duration-fields+
     scenario-benchmark-required-duration)
    (scenario-benchmark-put-fields!
     contract
     datum
     +scenario-benchmark-required-value-fields+
     scenario-benchmark-required-value)
    (hash-put!
     contract
     'expected_over_input_budget
     (scenario-benchmark-value
      datum
      'expected_over_input_budget
      (hash-get contract 'regression_budget)))
    (scenario-benchmark-put-defaults!
     contract
     datum
     +scenario-benchmark-default-fields+)
    contract))

;; : (-> BenchmarkContract BenchmarkContractDatum (List BenchmarkContractKey)
;;        (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue)
;;        BenchmarkContract)
(def (scenario-benchmark-put-fields! contract datum keys value-ref)
  (for-each (lambda (key)
              (hash-put! contract key (value-ref datum key)))
            keys)
  contract)

;; : (-> BenchmarkContract BenchmarkContractDatum
;;        (List (Cons BenchmarkContractKey BenchmarkContractValue))
;;        BenchmarkContract)
(def (scenario-benchmark-put-defaults! contract datum defaults)
  (for-each (lambda (entry)
              (let (key (car entry))
                (hash-put!
                 contract
                 key
                 (scenario-benchmark-value datum key (cdr entry)))))
            defaults)
  contract)

;;; Required benchmark field lookup:
;;; - Missing baseline/target fields are contract errors, not optional legacy
;;;   defaults; otherwise new scenarios silently fall back to unhelpful gates.
;; : (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue )
(def (scenario-benchmark-required-value datum key)
  (let (entry (and (list? datum) (assoc key datum)))
    (if entry
      (cdr entry)
      (error "policy scenario benchmark missing required field" key))))

;; : (-> BenchmarkContractDatum BenchmarkContractKey DurationLiteral )
(def (scenario-benchmark-required-duration datum key)
  (let (value (scenario-benchmark-required-value datum key))
    (if (duration-literal? value)
      value
      (error "policy scenario benchmark invalid duration literal" key value))))

;;; Datum lookup boundary:
;;; - Missing benchmark fields fall back to contract defaults.
;;; - This keeps older scenarios readable while new fields become testable.
;; : (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue BenchmarkContractValue )
(def (scenario-benchmark-value datum key default)
  (let (entry (and (list? datum) (assoc key datum)))
    (if entry (cdr entry) default)))

;;; Performance gate boundary:
;;; - #f means the scenario records timing without enforcing a ceiling.
;;; - benchmark.ss remains the owner for configured time budgets.
;; : (-> BenchmarkContract (U Integer False) )
(def (scenario-benchmark-max-total contract)
  (hash-get contract 'max_total))

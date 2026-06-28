((max_total . 24ms)
 (observed_total . 7ms)
 (target_total . 14ms)
 (regression_budget . 18ms)
 (expected_over_input_budget . 3ms)
 (expected_over_input_note
  .
  "expected builds an explicit make-hash-table-eq index; the scenario gate compares collect/policy time while the repair removes repeated runtime alist scans")
 (observedTimings
  ((name . collect-before) (durationMs . 2) (durationNs . 2000000))
  ((name . collect-after) (durationMs . 3) (durationNs . 3000000))
  ((name . policy-before) (durationMs . 1) (durationNs . 1000000))
  ((name . policy-after) (durationMs . 1) (durationNs . 1000000)))
 (targetRationale
  .
  "alist-index-boundary keeps repeated inline assq/cdr detection parser-owned and validates the expected index/accessor repair inside a tight scenario timing gate")
 (maxCollectMs . 10)
 (observedCollectMs . 5)
 (maxParseMs . 14)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 3)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose
  .
  "R022 alist index scenario rejects repeated inline alist probing when a symbolic index or named accessor boundary should own the event shape")
 (feature . "alist-index-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R022")
 (optimizationFocus
  .
  "repeated inline assq/cdr alist probing to make-hash-table-eq index or named accessor boundary")
 (inputShape
  .
  "four exported event helpers repeat inline assq/cdr over one event alist")
 (expectedRepair
  .
  "one event-index builder stores symbolic keys in make-hash-table-eq and accessors read through hash-get")
 (expectedReferencePattern . "gerbil-compiler-symbol-index-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/optimize.ss#current-compile-mutators"
  "gerbil://gerbil/compiler/optimize-spec.ss#make-hash-table-eq-method-calls"
  "poo-flow/src/module-system/object-core-support/object.ss#poo-flow-module-object-field-index")
 (expectedQualitySignals
  "inline-alist-lookup-drift"
  "symbol-index-boundary"
  "named-accessor-boundary"
  "gerbil-upstream-idiom-boundary")
 (learnedStyleSources
  "gerbil://gerbil/compiler/optimize.ss"
  "gerbil://gerbil/compiler/optimize-spec.ss"
  "poo-flow/src/module-system/object-core-support/object.ss")
 (antiAiScaffoldIntent
  .
  "reject generated helpers that repeat local alist key spelling and linear scans instead of making the symbolic lookup boundary explicit")
 (scenarioQualityAxes
  "alist-index-boundary"
  "inline-alist-lookup-drift"
  "symbol-index-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate"
  "assert-input-expected-comparison")
 (tags "style" "alist" "hash-index" "anti-scaffold"))

((max_total . 24ms)
 (observed_total . 6ms)
 (target_total . 14ms)
 (regression_budget . 18ms)
 (expected_over_input_budget . 1ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2) (durationNs . 2000000))
  ((name . collect-after) (durationMs . 2) (durationNs . 2000000))
  ((name . policy-before) (durationMs . 1) (durationNs . 1000000))
  ((name . policy-after) (durationMs . 1) (durationNs . 1000000)))
 (targetRationale
  .
  "list-append-loop-performance keeps loop-local append detection parser-owned and validates the accumulator repair in a small millisecond gate")
 (maxCollectMs . 10)
 (observedCollectMs . 4)
 (maxParseMs . 14)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 2)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose
  .
  "R039 list append loop scenario rejects generated O(n^2) list growth when a cons/reverse accumulator or hash-index merge boundary should own the hot path")
 (feature . "list-append-loop-performance")
 (rule . "GERBIL-SCHEME-AGENT-R039")
 (optimizationFocus
  .
  "loop-local append list growth to cons/reverse-once accumulator or hash-index ordered-key merge")
 (inputShape
  .
  "one merge helper appends each chunk onto an accumulated list inside the named loop")
 (expectedRepair
  .
  "nested accumulators cons elements and reverse once at the boundary, matching poo-flow hash/index merge style for keyed list operations")
 (expectedReferencePattern . "gerbil-list-growth-loop-boundary")
 (expectedReferenceExamples
  "gerbil://std/misc/list.ss"
  "gerbil://gambit/tests/unit-tests/04-list/append_reverse.scm"
  "poo-flow/src/module-system/extension-support/merge.ss#hash-index-with-reverse-new-keys"
  "poo-flow/t/scenarios/performance/module-extension-list-merge/benchmark.ss")
 (expectedQualitySignals
  "list-growth-loop-performance"
  "loop-local-append-copy"
  "cons-reverse-once-boundary"
  "hash-index-with-ordered-keys"
  "anti-ai-list-scaffold")
 (learnedStyleSources
  "gerbil://std/misc/list.ss"
  "gerbil://gambit/tests/unit-tests/04-list/append_reverse.scm"
  "poo-flow/src/module-system/extension-support/merge.ss")
 (antiAiScaffoldIntent
  .
  "reject generated hot loops that repeatedly append onto an accumulator and copy the prefix on every iteration")
 (scenarioQualityAxes
  "list-growth-loop-performance"
  "anti-ai-list-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate"
  "assert-input-expected-comparison")
 (tags "style" "list" "loop" "append" "performance"))

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
  "list-random-access-loop-performance keeps loop-local list-ref detection parser-owned and validates the vector boundary repair in a small millisecond gate")
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
  "R041 list random access scenario rejects generated O(n^2) indexed traversals over lists when a vector or evector boundary should own random access")
 (feature . "list-random-access-loop-performance")
 (rule . "GERBIL-SCHEME-AGENT-R041")
 (optimizationFocus
  .
  "loop-local list-ref/list-tail random access to one list->vector boundary or std/misc/evector growable indexed storage")
 (inputShape
  .
  "one selection helper walks requested indexes and calls list-ref on the source list inside the loop")
 (expectedRepair
  .
  "source list is materialized once with list->vector and the hot loop uses vector-ref")
 (expectedReferencePattern . "gerbil-list-random-access-loop-boundary")
 (expectedReferenceExamples
  "gerbil://std/misc/evector.ss#evector-push!"
  "gerbil://std/misc/evector.ss#memoize-recursive-sequence"
  "gerbil://std/misc/vector.ss"
  "poo-flow/t/flow-strand-performance-test.ss#large-registry-performance-gate")
 (expectedQualitySignals
  "list-random-access-loop-performance"
  "loop-local-list-ref"
  "vector-boundary"
  "evector-growable-indexed-buffer"
  "anti-ai-indexed-list-scaffold")
 (learnedStyleSources
  "gerbil://std/misc/evector.ss"
  "gerbil://std/misc/vector.ss"
  "poo-flow/t/flow-strand-performance-test.ss")
 (antiAiScaffoldIntent
  .
  "reject generated indexed loops that repeatedly walk a list head with list-ref or list-tail")
 (scenarioQualityAxes
  "list-random-access-loop-performance"
  "anti-ai-indexed-list-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate"
  "assert-input-expected-comparison")
 (tags "style" "list" "loop" "indexed-access" "performance"))

((max_total . 100ms)
 (observed_total . 1ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-after) (durationMs . 1))
  ((name . batch-split) (durationMs . 1))
  ((name . scenario-root-projection) (durationMs . 1)))
 (targetRationale . "testing framework user-layer scope selection must stay in hot path range")
 (maxCollectMs . 50)
 (observedCollectMs . 1)
 (maxParseMs . 50)
 (observedParseMs . 1)
 (maxFileMs . 50)
 (observedFileMs . 1)
 (maxPhaseMs . 50)
 (observedPhaseMs . 1)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
 (purpose . "upstream Gerbil build/test user-layer improvement gate")
 (feature . "testing-framework-upstream-build-improvement")
 (rule . "GERBIL-SCHEME-TESTING-UPSTREAM-BUILD-IMPROVEMENT")
 (optimizationFocus . "keep upstream std/make/gxtest ownership while preserving incremental scope, receipts, and benchmark gates")
 (inputShape . "multi-suite testing project with explicit gxtest file, manifest root, and policy scenario id")
 (expectedRepair . "declare a thin build.ss testing project and pass upstream-selected scope into the framework without widening")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "batch-split"
  "scenario-root-projection"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "testing" "framework" "scenario" "performance" "hot"))

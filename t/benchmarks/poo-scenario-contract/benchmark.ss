((max_total . 100ms)
 (observed_total . 10ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 10))
  ((name . collect-after) (durationMs . 5))
  ((name . policy-before) (durationMs . 5))
  ((name . policy-after) (durationMs . 5)))
 (targetRationale . "POO scenario contract checks use the shared benchmark.ss framework gate")
 (maxCollectMs . 100)
 (observedCollectMs . 10)
 (maxParseMs . 100)
 (observedParseMs . 5)
 (maxFileMs . 100)
 (observedFileMs . 5)
 (maxPhaseMs . 100)
 (observedPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "framework-level benchmark.ss gate for POO scenario contract checks")
 (feature . "poo-scenario-contract-framework")
 (rule . "GERBIL-SCHEME-BENCHMARK-FRAMEWORK")
 (optimizationFocus . "benchmark.ss-driven gxtest framework gate")
 (inputShape . "POO scenario benchmark fixtures plus expected source trees")
 (expectedOutcome . "reuse benchmark/framework APIs instead of ad hoc timing assertions")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "benchmark" "framework" "poo" "scenario-contract"))

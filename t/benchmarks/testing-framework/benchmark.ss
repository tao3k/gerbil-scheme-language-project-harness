((max_total . 100ms)
 (observed_total . 5ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1))
  ((name . batch-split) (durationMs . 1))
  ((name . scenario-root-projection) (durationMs . 1)))
 (targetRationale . "testing framework user-interface checks must stay in hot policy range")
 (maxCollectMs . 50)
 (observedCollectMs . 3)
 (maxParseMs . 50)
 (observedParseMs . 2)
 (maxFileMs . 50)
 (observedFileMs . 1)
 (maxPhaseMs . 50)
 (observedPhaseMs . 1)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "framework-level testing API gate")
 (feature . "poo-shaped-testing-framework")
 (rule . "GERBIL-SCHEME-TESTING-FRAMEWORK")
 (optimizationFocus . "user-friendly gxtest expansion and receipt gate")
 (inputShape . "POO-shaped testing project with manifest root and batch runner")
 (expectedOutcome . "declare testing project once; let framework expand and receipt batches")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "batch-split"
  "scenario-root-projection"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "testing" "framework" "poo" "gxtest"))

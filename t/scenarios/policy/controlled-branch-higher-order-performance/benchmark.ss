((max_total . 25ms)
 (observed_total . 7ms)
 (target_total . 15ms)
 (regression_budget . 18ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 2)))
 (targetRationale
  .
  "observed baseline 7ms for controlled-branch-higher-order-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R014 higher-order branch repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "typed-combinator-style")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-014")
 (optimizationFocus . "higher-order branch repair")
 (inputShape . "conditional dispatch helper with repeated branch bodies")
 (expectedOutcome . "source-backed fun/compose/curry style")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "higher-order" "branch"))

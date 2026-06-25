((maxTotalMs . 25)
 (observedTotalMs . 7)
 (targetTotalMs . 15)
 (regressionBudgetMs . 18)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 2)))
 (targetRationale
  .
  "observed baseline 7ms for controlled-branch-higher-order-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R014 higher-order branch repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "typed-combinator-style")
 (rule . "GERBIL-SCHEME-AGENT-R014")
 (optimizationFocus . "higher-order branch repair")
 (inputShape . "conditional dispatch helper with repeated branch bodies")
 (expectedRepair . "source-backed fun/compose/curry style")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "higher-order" "branch"))

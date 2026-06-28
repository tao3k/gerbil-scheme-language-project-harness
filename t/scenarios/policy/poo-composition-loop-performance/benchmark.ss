((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 4ms for poo-composition-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R030 POO composition repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-composition")
 (rule . "GERBIL-SCHEME-AGENT-R030")
 (optimizationFocus . "loop-local POO composition")
 (inputShape . "manual loop repeatedly composing POO objects")
 (expectedRepair . "accumulate scalar state and apply one final composition")
 (hotPathExemption . "poo-composition-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "poo-composition"
  "single-boundary-object"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rewrite measured loop-local composition into a generic pipeline without preserving the one-boundary object construction")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "composition"))

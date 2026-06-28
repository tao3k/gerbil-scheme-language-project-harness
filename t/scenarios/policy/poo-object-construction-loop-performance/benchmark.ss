((max_total . 25ms)
 (observed_total . 7ms)
 (target_total . 15ms)
 (regression_budget . 18ms)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 7ms for poo-object-construction-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R033 object construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-object-construction")
 (rule . "GERBIL-SCHEME-AGENT-R033")
 (optimizationFocus . "loop-local object construction")
 (inputShape . "manual loop repeatedly constructing POO objects")
 (expectedRepair . "hoist stable construction or build one final object")
 (hotPathExemption . "object-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "object-construction"
  "single-boundary-object"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not construct stable POO objects inside a measured loop when scalar/list/hash accumulation can preserve one final boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "construction"))

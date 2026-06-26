((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-validation-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R031 validation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-validation")
 (rule . "GERBIL-SCHEME-AGENT-R031")
 (optimizationFocus . "loop-local validation")
 (inputShape . "manual loop repeatedly validating the same POO shape")
 (expectedRepair . "validate once outside the loop")
 (hotPathExemption . "poo-validation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "validation"
  "single-boundary-check"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not repeat stable validation inside a measured loop; keep one validation boundary before scalar/object work")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "validation"))

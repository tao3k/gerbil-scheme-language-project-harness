((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-function-type-construction-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R034 Function type construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-function-type-construction")
 (rule . "GERBIL-SCHEME-AGENT-R034")
 (optimizationFocus . "loop-local function type construction")
 (inputShape
  .
  "manual loop repeatedly constructing stable Function type objects")
 (expectedRepair . "hoist stable Function type object to a named binding")
 (hotPathExemption . "type-object-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "function-type-object"
  "hoisted-type-binding"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rebuild stable function type objects inside a measured loop; keep type bindings outside the loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "type" "function"))

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
  "observed baseline 3ms for poo-type-construction-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R034 type construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-type-construction")
 (rule . "GERBIL-SCHEME-AGENT-R034")
 (optimizationFocus . "loop-local type construction")
 (inputShape
  .
  "manual loop repeatedly constructing stable POO/MOP type objects")
 (expectedRepair . "hoist stable type object to a named binding")
 (hotPathExemption . "type-object-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "type-object"
  "hoisted-type-binding"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rebuild stable type objects inside a measured loop; keep named type bindings outside the loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "type"))

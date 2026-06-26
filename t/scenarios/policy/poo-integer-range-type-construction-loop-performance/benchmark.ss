((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 4ms for poo-integer-range-type-construction-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R034 integer range type construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-integer-range-type-construction")
 (rule . "GERBIL-SCHEME-AGENT-R034")
 (optimizationFocus . "loop-local integer range type construction")
 (inputShape
  .
  "manual loop repeatedly constructing stable IntegerRange type objects")
 (expectedRepair . "hoist stable IntegerRange type object to a named binding")
 (hotPathExemption . "numeric-type-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "numeric-type-object"
  "hoisted-type-binding"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rebuild integer range numeric type objects inside a measured loop; keep stable type objects hoisted")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "type" "integer-range"))

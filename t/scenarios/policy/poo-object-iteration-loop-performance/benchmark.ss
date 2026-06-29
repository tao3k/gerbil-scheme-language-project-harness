((max_total . 25ms)
 (observed_total . 6ms)
 (target_total . 15ms)
 (regression_budget . 19ms)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 6ms for poo-object-iteration-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R029 object iteration repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-object-iteration")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-029")
 (optimizationFocus . "loop-local object iteration")
 (inputShape . "manual loop repeatedly iterating a POO object")
 (expectedRepair . "keep the stable profile as native .o and iterate from one boundary snapshot or direct slot access")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "poo-object-iteration-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "object-iteration"
  "single-boundary-snapshot"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not introduce repeated object iteration snapshots inside a measured loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "iteration"))

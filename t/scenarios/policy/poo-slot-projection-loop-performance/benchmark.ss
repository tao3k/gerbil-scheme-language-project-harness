((max_total . 25ms)
 (observed_total . 5ms)
 (target_total . 15ms)
 (regression_budget . 20ms)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 5ms for poo-slot-projection-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R029 slot projection repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-projection")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-029")
 (optimizationFocus . "loop-local slot projection")
 (inputShape . "manual loop repeatedly projecting POO slots")
 (expectedRepair . "project once at a boundary or use direct slot access")
 (hotPathExemption . "poo-slot-projection-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "slot-projection"
  "direct-slot-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not materialize broad slot projections inside a measured loop when direct slot reads or one projection boundary preserve behavior")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "projection"))

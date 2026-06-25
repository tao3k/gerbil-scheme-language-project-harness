((maxTotalMs . 25)
 (observedTotalMs . 5)
 (targetTotalMs . 15)
 (regressionBudgetMs . 20)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 5ms for poo-slot-projection-loop-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R029 slot projection repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-projection")
 (rule . "GERBIL-SCHEME-AGENT-R029")
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

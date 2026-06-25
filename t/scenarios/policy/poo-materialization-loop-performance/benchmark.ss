((maxTotalMs . 25)
 (observedTotalMs . 4)
 (targetTotalMs . 15)
 (regressionBudgetMs . 21)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 4ms for poo-materialization-loop-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R029 materialization repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-materialization")
 (rule . "GERBIL-SCHEME-AGENT-R029")
 (optimizationFocus . "loop-local materialization")
 (inputShape . "manual loop repeatedly materializing POO object data")
 (expectedRepair . "materialize once at a boundary before iteration")
 (hotPathExemption . "poo-materialization-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "object-materialization"
  "single-boundary-snapshot"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not introduce repeated materialization inside a measured loop; keep one boundary snapshot")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "materialization"))

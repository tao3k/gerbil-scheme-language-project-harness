((maxTotalMs . 25)
 (observedTotalMs . 8)
 (targetTotalMs . 15)
 (regressionBudgetMs . 17)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 8ms for poo-real-dashboard-workflow-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (maxCollectMs . 12)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 8)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "real dashboard workflow proves POO API usage can stay boundary-oriented and performance-gated")
 (feature . "poo-real-dashboard-workflow")
 (rule . "GERBIL-SCHEME-AGENT-R028/R029/R030/R031/R033/R035/R037")
 (optimizationFocus . "multi-api POO workflow")
 (inputShape
  .
  "agent-style loop mixes object construction, validation, projection, predicates, clone overrides, composition, debug tracing, and materialization")
 (expectedRepair
  .
  "use POO APIs at ingestion/materialization/update boundaries, project events to scalar deltas first, and keep the hot scoring loop scalar-only")
 (hotPathExemption . "poo-boundary-api-workflow")
 (hotPathEvidence
  "manual-loop"
  "poo-api-boundary"
  "scalar-state-accumulation"
  "multi-rule-performance"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not move POO object construction, validation, tracing, materialization, or multi-slot predicates back into the loop without a benchmark proving it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "workflow" "dashboard" "performance"))

((maxTotalMs . 25)
 (observedTotalMs . 3)
 (targetTotalMs . 15)
 (regressionBudgetMs . 22)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-debug-instrumentation-loop-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R035 debug instrumentation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-debug-instrumentation")
 (rule . "GERBIL-SCHEME-AGENT-R035")
 (optimizationFocus . "loop-local debug instrumentation")
 (inputShape . "manual loop repeatedly wrapping trace-poo instrumentation")
 (expectedRepair . "hoist trace-poo outside the loop")
 (hotPathExemption . "debug-instrumentation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "debug-wrapper"
  "hoisted-setup-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not introduce repeated debug wrappers inside a measured loop; keep instrumentation at one setup boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "debug"))

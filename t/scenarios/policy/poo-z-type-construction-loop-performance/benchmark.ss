((maxTotalMs . 25)
 (observedTotalMs . 6)
 (targetTotalMs . 15)
 (regressionBudgetMs . 19)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 6ms for poo-z-type-construction-loop-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R034 modular integer type construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-modular-integer-type-construction")
 (rule . "GERBIL-SCHEME-AGENT-R034")
 (optimizationFocus . "loop-local modular integer type construction")
 (inputShape . "manual loop repeatedly constructing stable Z/ type objects")
 (expectedRepair . "hoist stable Z/ type object to a named binding")
 (hotPathExemption . "numeric-type-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "numeric-type-object"
  "hoisted-type-binding"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rebuild modular numeric type objects inside a measured loop; keep stable type objects hoisted")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "type" "modular"))

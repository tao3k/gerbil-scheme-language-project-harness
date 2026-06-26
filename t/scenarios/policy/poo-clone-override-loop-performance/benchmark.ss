((maxTotalMs . 25)
 (observedTotalMs . 5)
 (targetTotalMs . 15)
 (regressionBudgetMs . 20)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 5ms for poo-clone-override-loop-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 6)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R028 clone override repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-clone-override")
 (rule . "GERBIL-SCHEME-AGENT-R028")
 (optimizationFocus . "loop-local clone override")
 (inputShape . "manual loop repeatedly cloning POO state")
 (expectedRepair . "accumulate scalar loop state and apply one final clone")
 (hotPathExemption . "poo-loop-state-mutation")
 (hotPathEvidence
  "manual-loop"
  "clone-override"
  "scalar-state-accumulation"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not replace measured scalar loop accumulation with higher-order composition unless a benchmark proves it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "clone"))

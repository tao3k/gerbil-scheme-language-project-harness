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
  "observed baseline 3ms for poo-slot-spec-mutation-loop-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R036 slot spec mutation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-spec-mutation")
 (rule . "GERBIL-SCHEME-AGENT-R036")
 (optimizationFocus . "loop-local slot spec mutation")
 (inputShape . "manual loop repeatedly mutating POO slot definitions")
 (expectedRepair . "define slots once and mutate values intentionally")
 (hotPathExemption . "slot-spec-mutation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "slot-spec-mutation"
  "value-mutation-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not perform structural slot-spec mutation inside a measured loop; keep structure setup outside and value mutation explicit")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "slot-spec"))

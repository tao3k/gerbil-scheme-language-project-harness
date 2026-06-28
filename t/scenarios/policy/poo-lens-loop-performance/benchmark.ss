((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-lens-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R032 lens modify repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-lens")
 (rule . "GERBIL-SCHEME-AGENT-R032")
 (optimizationFocus . "loop-local lens modification")
 (inputShape . "manual loop repeatedly applying lens-style POO updates")
 (expectedRepair
  .
  "accumulate scalar lens target state and apply one final update")
 (hotPathExemption . "poo-lens-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "lens-update"
  "scalar-state-accumulation"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not replace measured scalar lens accumulation with repeated object lens updates")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "lens"))

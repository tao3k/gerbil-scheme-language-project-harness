((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 3ms for poo-construction-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R027 POO construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-construction")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-027")
 (optimizationFocus . "large data-shaped object construction")
 (inputShape . "broad mostly-data POO object construction")
 (expectedRepair . "object<-alist construction boundary")
 (hotPathExemption . "broad-data-construction-cost")
 (hotPathEvidence
  "slot-spec-count"
  "object-construction"
  "boundary-construction"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not expand broad data construction into procedural slot writes when object<-alist preserves a single construction boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "construction" "data-shape"))

((max_total . 25ms)
 (observed_total . 8ms)
 (target_total . 15ms)
 (regression_budget . 17ms)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 4))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 8ms for poo-slot-predicate-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R037 slot predicate repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-predicate")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-037")
 (optimizationFocus . "loop-local slot predicate")
 (inputShape . "manual loop repeatedly checking stable slot predicates")
 (expectedRepair
  .
  "hoist predicate result or predicate closure outside the loop")
 (hotPathExemption . "poo-slot-predicate-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "slot-predicate"
  "hoisted-predicate-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not recompute stable slot predicate closures inside a measured loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "predicate"))

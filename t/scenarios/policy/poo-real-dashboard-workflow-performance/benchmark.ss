((max_total . 25ms)
 (observed_total . 8ms)
 (target_total . 15ms)
 (regression_budget . 17ms)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 8ms for poo-real-dashboard-workflow-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
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
 (purpose . "real dashboard workflow proves POO API usage can stay boundary-oriented and performance-gated")
 (feature . "poo-real-dashboard-workflow")
   (rule . "GERBIL-SCHEME-AGENT-POO-DASHBOARD-WORKFLOW-037")
 (optimizationFocus . "multi-api POO workflow")
 (inputShape
  .
  "agent-style loop mixes object construction, validation, projection, predicates, clone overrides, composition, debug tracing, and materialization")
 (expectedOutcome
  .
  "keep dashboard config as native .o, use adapters only at external ingestion/materialization boundaries, project events to scalar deltas first, and keep the hot scoring loop scalar-only")
 (nativePooPrimary . #t)
 (adapterBoundary . "external event alists may be adapted at ingestion; profile/config/update paths stay native .o/.cc")
 (hotPathExemption . "poo-boundary-api-workflow")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
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

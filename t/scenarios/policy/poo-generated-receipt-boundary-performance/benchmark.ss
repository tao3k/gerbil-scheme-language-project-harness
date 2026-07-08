((max_total . 18ms)
 (observed_total . 5ms)
 (target_total . 10ms)
 (regression_budget . 13ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "generated receipt boundary policy must stay single-digit ms while rejecting adapter-object internal receipt state")
 (maxCollectMs . 8)
 (observedCollectMs . 0)
 (maxParseMs . 10)
 (observedParseMs . 0)
 (maxFileMs . 4)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 256)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "generated runtime receipt repair scenario keeps policy analysis fast and boundary-correct")
 (feature . "poo-generated-receipt-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-043")
 (optimizationFocus . "fixed defstruct generated receipt state with explicit bounded ->alist ABI projection")
 (inputShape . "agent-generated receipt builder using object<-alist for internal runtime state")
 (expectedOutcome . "model generated receipt state with defstruct and serialize through one named ->alist function at presentation/runtime ABI boundaries")
 (generatedRuntimeBoundary . #t)
 (hotPathExemption . "generated-receipt-boundary")
 (hotPathEvidence
  "generated-runtime-receipt"
  "defstruct-internal-state"
  "bounded-alist-boundary"
  "adapter-boundary"
  "single-digit-ms-target"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rewrite user native POO declarations; only generated receipt/manifest/snapshot/handoff state should move from object<-alist adapters to defstruct plus ->alist")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "receipt" "defstruct" "boundary-alist" "performance"))

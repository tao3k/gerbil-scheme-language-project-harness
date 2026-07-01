((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-validation-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
(iterations . 3)
 (unit . "ms")
 (purpose . "R031 validation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-validation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-031")
 (optimizationFocus . "loop-local validation")
 (inputShape . "manual loop repeatedly validating the same POO shape")
 (expectedRepair . "keep the stable profile as native .o and validate once outside the loop")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the typed profile shape")
 (optimizerVisibility
  .
  "stable POO validation is performed once at the checked boundary, leaving the loop with a validated native object and scalar state")
 (expectedQualitySignals
  "single-validation-boundary"
  "validated-native-object"
  "scalar-loop-state"
  "no-loop-local-validation")
 (learnedStyleSources
  "gerbil://mop.ss#item/def/MonomorphicObject"
  "gerbil://mop.ss#item/def/validate"
  "gerbil://gerbil/core/contract.ss#using-class-interface-boundary")
 (hotPathExemption . "poo-validation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "validation"
  "single-boundary-check"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not repeat stable validation inside a measured loop; keep one validation boundary before scalar/object work")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "validation"))

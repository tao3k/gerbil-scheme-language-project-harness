((max_total . 29ms)
 (observed_total . 14ms)
 (target_total . 19ms)
 (regression_budget . 15ms)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 8))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 2)))
 (targetRationale
  .
  "observed baseline 14ms for slot-lens-boundary; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 24)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 16)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 slot lens scenario keeps learned descriptor/lens repair within the scenario-owned timing gate")
 (feature . "slot-lens-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "local slot descriptor and lens boundary")
 (inputShape
  .
  "single exported function mixes Slot, Lens, Get, Set, Modify, and Validate responsibilities")
 (expectedOutcome
  .
  "local slot/lens helpers split get, set, modify, and validation without adding gerbil-poo or gerbil-utils dependencies")
 (expectedReferencePattern . "slot-lens-boundary")
 (expectedReferenceExamples
  "gerbil-poo/mop.ss#slot-checker"
  "gerbil-poo/mop.ss#Lens.modify"
  "gerbil-poo/mop.ss#slot-lens")
 (expectedQualitySignals
  "slot-descriptor-boundary"
  "lens-get-set-modify-boundary"
  "local-lens-helper")
 (learnedStyleSources "gerbil-poo")
 (antiAiScaffoldIntent
  .
  "reject repeated slot access scaffolding when contract categories prove a lens boundary")
 (scenarioQualityAxes "slot-lens-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "slot" "lens" "descriptor-boundary"))

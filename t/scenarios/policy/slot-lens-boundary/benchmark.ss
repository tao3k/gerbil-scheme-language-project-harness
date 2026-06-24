((maxTotalMs . 1000)
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 slot lens scenario keeps learned descriptor/lens repair within the scenario-owned timing gate")
 (feature . "slot-lens-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "local slot descriptor and lens boundary")
 (inputShape . "single exported function mixes Slot, Lens, Get, Set, Modify, and Validate responsibilities")
 (expectedRepair . "local slot/lens helpers split get, set, modify, and validation without adding gerbil-poo or gerbil-utils dependencies")
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
 (antiAiScaffoldIntent . "reject repeated slot access scaffolding when contract categories prove a lens boundary")
 (scenarioQualityAxes "slot-lens-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after" "assert-time-gate" "assert-memory-gate")
 (tags "style" "slot" "lens" "descriptor-boundary"))

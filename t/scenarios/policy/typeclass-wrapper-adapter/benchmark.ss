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
 (purpose . "R013 typeclass wrapper scenario keeps learned wrap/unwrap method adapter repair within the scenario-owned timing gate")
 (feature . "typeclass-wrapper-adapter")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "local wrapper/functor method adapter lift")
 (inputShape . "single define-type mixes Wrapper, Functor, wrap/unwrap, and IO/JSON/bytes/marshal method lambdas")
 (expectedRepair . "local adapter helpers lift protocol methods through wrap/unwrap without adding gerbil-poo dependencies")
 (expectedReferencePattern . "typeclass-wrapper-adapter")
 (expectedReferenceExamples
  "gerbil-poo/fun.ss#methods.io<-wrap"
  "gerbil-poo/fun.ss#Wrapper."
  "gerbil-poo/fun.ss#Wrap^.")
 (expectedQualitySignals
  "wrapper-adapter-lift"
  "wrap-unwrap-boundary"
  "method-protocol-lift")
 (learnedStyleSources "gerbil-poo")
 (antiAiScaffoldIntent . "reject table-shaped wrapper method scaffolding when POO typeclass facts expose protocol lifts")
 (scenarioQualityAxes "poo-typeclass-algebra-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after" "assert-time-gate" "assert-memory-gate")
 (tags "style" "typeclass" "wrapper" "method-adapter"))

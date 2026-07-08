((max_total . 27ms)
 (observed_total . 12ms)
 (target_total . 17ms)
 (regression_budget . 15ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 6))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 3)))
 (targetRationale
  .
  "observed baseline 12ms for typeclass-wrapper-adapter; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 18)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 12)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 typeclass wrapper scenario keeps learned wrap/unwrap method adapter repair within the scenario-owned timing gate")
 (feature . "typeclass-wrapper-adapter")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "local wrapper/functor method adapter lift")
 (inputShape
  .
  "single define-type mixes Wrapper, Functor, wrap/unwrap, and IO/JSON/bytes/marshal method lambdas")
 (expectedOutcome
  .
  "local adapter helpers lift protocol methods through wrap/unwrap without adding gerbil-poo dependencies")
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
 (antiAiScaffoldIntent
  .
  "reject table-shaped wrapper method scaffolding when POO typeclass facts expose protocol lifts")
 (scenarioQualityAxes "poo-typeclass-algebra-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "typeclass" "wrapper" "method-adapter"))

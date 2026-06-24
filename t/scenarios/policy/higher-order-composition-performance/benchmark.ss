((maxTotalMs . 1000)
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 higher-order composition scenario keeps wrapper-lambda repair within the scenario-owned timing gate")
 (feature . "higher-order-composition")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "wrapper lambda to composition boundary")
 (inputShape . "repeated wrapper lambdas around a reusable string transform")
 (expectedRepair . "compose/cut pipeline with full typed documentation")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#left-to-right"
  "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate")
 (expectedQualitySignals
  "function-pipeline-abstraction"
  "cut-prefix-predicate"
  "thin-wrapper-elimination")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent . "reject repeated wrapper-lambda scaffolding when compose/cut expresses the data flow")
 (scenarioQualityAxes "higher-order-composition" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after")
 (tags "style" "higher-order" "composition"))

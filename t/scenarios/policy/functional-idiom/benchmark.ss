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
 (purpose . "R013 functional idiom scenario keeps manual fold and local destructuring repair within the scenario-owned timing gate")
 (feature . "functional-idiom")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "manual recursion to fold/pipeline and lambda-match boundary")
 (inputShape . "single exported function uses named-let, cdr/car traversal, and an accumulator over a list")
 (expectedRepair . "foldl total, !>/curry pipeline, and named lambda-match classifier with full typed documentation")
 (expectedReferencePattern . "list-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
  "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
  "gerbil-utils/list.ss#list-map"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "list-combinator-boundary"
  "fold-reducer-boundary"
  "cut-predicate-specialization"
  "map-fold-boundary"
  "lambda-match-destructuring")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent . "reject hand-written traversal and anonymous destructuring when fold, cut/curry pipeline, or lambda-match exposes the data flow")
 (scenarioQualityAxes "functional-idiom" "list-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after" "assert-time-gate" "assert-memory-gate")
 (tags "style" "functional" "fold" "pipeline" "lambda-match" "anti-scaffold"))

((maxTotalMs . 1000)
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 list combinator scenario keeps anti-scaffold traversal repair within the scenario-owned timing gate")
 (feature . "list-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "manual list recursion to expression-level traversal boundary")
 (inputShape . "single exported function uses named-let, reverse accumulator, and inline selection/projection over a list")
 (expectedRepair . "local selector plus filter-map traversal with full typed documentation")
 (expectedReferencePattern . "list-combinator-boundary")
 (expectedReferenceExamples
  "gerbil-utils/list.ss#list-map"
  "gerbil-utils/list.ss#list<-monoid"
  "gerbil-utils/list.ss#with-deduplicated-list-builder"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "list-combinator-boundary"
  "map-fold-boundary"
  "filter-map-selection-projection"
  "lambda-match-list-destructuring"
  "list-builder-output-shape")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent . "reject hand-written list traversal scaffolding when a mapper, selector, reducer, filter-map, fold, or builder boundary expresses the data flow")
 (scenarioQualityAxes "list-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after")
 (tags "style" "list" "combinator" "anti-scaffold"))

((maxTotalMs . 25)
 (observedTotalMs . 8)
 (targetTotalMs . 15)
 (regressionBudgetMs . 17)
 (observedTimings ((collect-before . 2)
                   (collect-after . 4)
                   (policy-before . 1)
                   (policy-after . 1)))
 (targetRationale . "observed baseline 8ms for destructuring-combinator-boundary; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 destructuring combinator scenario keeps repeated pair/alist access repair within the scenario-owned timing gate while preferring native match mechanisms when they remove runtime probing")
 (feature . "destructuring-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "temporary destructuring scaffolding to native match, selector, or syntax-local boundary")
 (inputShape . "single exported function repeats cdr/assq alist access and temporary let bindings over an event record")
 (expectedRepair . "local selector boundary plus full typed documentation")
 (expectedReferencePattern . "destructuring-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#applicative-destructuring"
  "gerbil://gerbil/core/match.ss#syntax-local-match-macro"
  "gerbil://gerbil/core/match.ss#syntax-local-value-class-accessors"
  "gerbil://gerbil/core/match.ss#defsyntax-for-match"
  "gerbil-utils/base.ss#lambda-match"
  "gerbil-utils/base.ss#let-match"
  "gerbil-poo/mop.ss#slot-lens"
  "gerbil-poo/mop.ss#Lens.compose")
 (expectedQualitySignals
  "destructuring-combinator-boundary"
  "applicative-destructuring-boundary"
  "syntax-local-match-extension"
  "compile-time-metadata-lookup"
  "early-syntax-error-boundary"
  "lambda-match-destructuring"
  "named-selector-boundary"
  "slot-lens-boundary"
  "temporary-binding-collapse")
 (learnedStyleSources "gerbil://" "gerbil-utils" "gerbil-poo")
 (antiAiScaffoldIntent . "reject repeated pair/alist/object destructuring scaffolding when native match/apply destructuring, syntax-local lookup, a selector, lambda-match, or slot/lens boundary expresses the data shape")
 (scenarioQualityAxes "destructuring-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after" "assert-time-gate" "assert-memory-gate")
 (tags "style" "destructuring" "selector" "anti-scaffold"))

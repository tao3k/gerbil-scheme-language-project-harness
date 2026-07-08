((max_total . 30ms)
 (observed_total . 11ms)
 (target_total . 18ms)
 (regression_budget . 19ms)
 (observedTimings . (((name . collect-before) (durationMs . 4))
                     ((name . collect-after) (durationMs . 4))
                     ((name . policy-before) (durationMs . 2))
                     ((name . policy-after) (durationMs . 1))))
 (targetRationale . "observed baseline 10-11ms for complex destructuring-combinator-boundary; target keeps native match repair visible and max_total is the hard regression ceiling")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 destructuring combinator scenario keeps repeated pair/alist access repair within the scenario-owned timing gate while preferring native match mechanisms when they remove runtime probing")
 (feature . "destructuring-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "temporary destructuring scaffolding to native match, selector, or syntax-local boundary")
 (inputShape . "three exported helpers repeat assq/cdr alist probing, defaults, and conditional routing over one event record")
 (expectedOutcome . "single with/match destructuring boundary, RouteKey domain type, core match dispatch, and full typed documentation")
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

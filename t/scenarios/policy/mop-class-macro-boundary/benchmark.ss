((target_total . 18ms)
 (max_total . 30ms)
 (observed_total . 4ms)
 (regression_budget . 26ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 4ms for scoped MOP class macro boundary; target keeps the class macro policy scenario in a small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 15)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 10)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 MOP class macro scenario keeps defclass-style descriptor generation and runtime method binding under the scenario-owned timing gate")
 (feature . "mop-class-macro-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "Gerbil core/mop defclass descriptor, mixin slot accessor, and defmethod binding boundaries")
 (inputShape
  .
  "macro owner mixes class descriptor tables, slot layout, mixin accessors and mutators, constructor/predicate metadata, method binding, and slot contract/default metadata")
 (expectedRepair
  .
  "native defclass/defmethod surface with descriptor metadata declared once and runtime behavior kept in ordinary method helpers")
 (learnedStyleSources
  "gerbil://gerbil/core/mop.ss#defclass"
  "gerbil://gerbil/core/mop.ss#defmethod"
  "gerbil://gerbil/core/mop.ss#generate-defclass")
 (antiAiScaffoldIntent
  .
  "reject table-shaped class DSL macros that reimplement Gerbil MOP descriptor, slot accessor, mutator, and method-binding semantics in one syntax owner")
 (scenarioQualityAxes
  "mop-class-macro-boundary"
  "class-descriptor-macro-boundary"
  "mixin-slot-accessor-boundary"
  "method-binding-boundary"
  "anti-ai-scaffold")
 (expectedReferencePattern . "gerbil-core-mop-class-macro-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/mop.ss#defclass"
  "gerbil://gerbil/core/mop.ss#defmethod"
  "gerbil://gerbil/core/mop.ss#generate-defclass"
  "gerbil://gerbil/core/mop.ss#class-type-info"
  "gerbil://gerbil/core/mop.ss#get-mixin-slots"
  "gerbil://gerbil/core/mop.ss#bind-method!")
 (expectedQualitySignals
  "mop-class-macro-boundary"
  "class-descriptor-macro-boundary"
  "class-type-info-boundary"
  "mixin-slot-accessor-boundary"
  "method-binding-boundary"
  "constructor-predicate-metadata-boundary"
  "slot-contract-metadata-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro" "mop" "class"))

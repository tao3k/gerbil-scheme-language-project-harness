((maxTotalMs . 35)
 (observedTotalMs . 12)
 (targetTotalMs . 20)
 (regressionBudgetMs . 23)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 5))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 2)))
 (targetRationale
  .
  "gerbil-interface-contract-boundary keeps native using/interface contract repair under the scenario-owned timing gate")
 (maxCollectMs . 15)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 10)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 native Gerbil interface/contract scenario catches one-owner slot contract scaffolding and repairs it with local typed descriptor helpers")
 (feature . "gerbil-interface-contract-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "Gerbil native using/interface contract boundary")
 (inputShape
  .
  "single exported owner collapses Interface, Contract, Slot, Get, Set, Modify, and Validate responsibilities")
 (expectedRepair
  .
  "introduce a local typed descriptor and use Gerbil `using` slot access while keeping validation and mutation in separate helpers")
 (expectedReferencePattern . "gerbil-native-interface-contract-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/contract.ss#using-class-interface-boundary"
  "gerbil://gerbil/core/contract.ss#slot-contract-normalize"
  "gerbil://gerbil/compiler/optimize-call.ss#using-class-slot-access"
  "gerbil://gerbil/compiler/optimize-base.ss#class-method-table")
 (expectedQualitySignals
  "slot-lens-boundary"
  "gerbil-native-using-boundary"
  "typed-descriptor-slot-access"
  "contract-projection-boundary")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "teach agents to use Gerbil typed object boundaries from parser-owned contract evidence instead of broad slot/update scaffolding")
 (scenarioQualityAxes
  "gerbil-interface-contract-boundary"
  "slot-lens-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style"
       "gerbil-native"
       "using"
       "interface"
       "contract"
       "slot"
       "descriptor-boundary"))

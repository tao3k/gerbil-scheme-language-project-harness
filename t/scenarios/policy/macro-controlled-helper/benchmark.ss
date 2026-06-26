((maxTotalMs . 25)
 (observedTotalMs . 7)
 (targetTotalMs . 15)
 (regressionBudgetMs . 18)
 (observedTimings
  ((name . collect-before) (durationMs . 0))
  ((name . collect-after) (durationMs . 4))
  ((name . policy-before) (durationMs . 2))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 7ms for macro-controlled-helper; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 12)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 8)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R011 controlled macro helper scenario keeps macro runtime-source policy within the timing gate")
 (feature . "macro-helper-runtime-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R011")
 (optimizationFocus . "controlled macro helper boundary")
 (inputShape . "macro transformer without local parser helper")
 (expectedRepair . "syntax-case transformer with local syntax error helper")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro" "runtime-boundary"))

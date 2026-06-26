((maxTotalMs . 105)
 (observedTotalMs . 5)
 (targetTotalMs . 100)
 (regressionBudgetMs . 100)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "downstream gxtest policy scope runs through the real gxtest test boundary and must stay below a small fixture budget while following imported source owners")
 (maxCollectMs . 174)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 116)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose
  .
  "R013 downstream gxtest scenario reproduces unit-tests importing project-policy-test while source warnings live behind another imported test")
 (feature . "downstream-gxtest-policy-scope")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "gxtest files-scope import closure must include tested package-local source owners")
 (inputShape
  .
  "unit-tests imports project-policy-test and cli-test; cli-test imports src/cli where the R013 warning lives")
 (expectedRepair
  .
  "gxtest policy report on unit-tests sees src/cli before repair and passes after the source owner uses fold style")
 (expectedReferencePattern . "loop-driver-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "basic-syntax-scaffold"
  "manual-loop-drift"
  "pure-loop-driver-combinator-boundary"
  "fold-reducer-boundary")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject a green gxtest result when the policy suite only checks the project-policy module and misses source owners reached by the real unit test root")
 (scenarioQualityAxes
  "downstream-gxtest"
  "gxtest-policy-scope"
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
       "gxtest"
       "downstream"
       "scope"
       "import-closure"
       "anti-scaffold"))

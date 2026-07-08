((max_total . 25ms)
 (observed_total . 7ms)
 (target_total . 15ms)
 (regression_budget . 18ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 2))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed actor-runtime-boundary receipt is 7ms total; target keeps actor runtime contract checks in the small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 separates Gerbil actor runtime, mailbox protocol, lifecycle, shutdown, and parameter propagation responsibilities")
 (feature . "actor-runtime-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "actor mailbox protocol and lifecycle helper boundary")
 (inputShape
  .
  "one actor helper mixes Actor, Mailbox, Send, Receive, Spawn, Join, Shutdown, and Parameter responsibilities")
 (expectedOutcome
  .
  "split actor spawn, mailbox delivery, shutdown, and parameter-propagation helpers without adding dependency requirements")
 (expectedReferencePattern . "gerbil-actor-runtime-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v18/executor.ss#spawn-actor-worker"
  "gerbil://std/actor-v18/server.ss#actor-server-loop"
  "gerbil://std/actor-v18/message.ss#mailbox-message"
  "gerbil://gerbil/runtime/control.ss#call-with-parameters")
 (expectedQualitySignals
  "actor-runtime-boundary"
  "mailbox-protocol-boundary"
  "actor-lifecycle-helper"
  "actor-shutdown-boundary"
  "actor-parameter-propagation")
 (learnedStyleSources
  "gerbil://std/actor-v18/executor.ss"
  "gerbil://std/actor-v18/server.ss"
  "gerbil://gerbil/runtime/control.ss")
 (antiAiScaffoldIntent
  .
  "reject all-in-one actor loops that hide mailbox protocol, lifecycle, shutdown, supervision, and parameter propagation")
 (scenarioQualityAxes
  "actor-runtime-boundary"
  "mailbox-protocol-boundary"
  "runtime-control")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "actor" "runtime" "mailbox"))

(max_total . 140ms)
(observed_total . 20ms)
(target_total . 110ms)
(targetRationale
  .
  "CLI error-boundary scenario enforces command boundary without leaking raw argv handling.")
(maxRssMb . 512)
(rule . "GERBIL-SCHEME-AGENT-POLICY-013")
(purpose . "R013 structured CLI error boundary keeps argv parsing, validation, and error display inside explicit typed boundaries.")
(regression_budget
  (parseMs 20)
  (policyMs 40)
  (scenarioMs 120)
  (maxFindings 4))

(observedTimings
  (collectProjectMs 9)
  (policyFindingsMs 6)
  (scenarioContextMs 4)
  (scenarioLearningMs 3))

(scenarioIntent
  (id structured-cli-error-boundary)
  (policy R013)
  (mode reasoning-first)
  (source gerbil-v0.19-staging std/cli/getopt std/error)
  (goal "Replace hand-written argv/error/display plumbing with a typed CLI and error boundary."))

(scenarioQualityAxes
  (structuredCliBoundary
   (positive std-cli-getopt command option current-getopt-parser)
   (negative raw-argv-case repeated-usage-strings))
  (typedErrorBoundary
   (positive deferror-class raise/context report-errors with-exit-on-error)
   (negative scattered-error-display-exit))
  (agentReasoning
   (positive "choose the boundary before writing command code")
   (negative "post-write rewrite catalog")))

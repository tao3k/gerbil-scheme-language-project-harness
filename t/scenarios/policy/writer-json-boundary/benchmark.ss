(max_total . 150ms)
(observed_total . 30ms)
(target_total . 120ms)
(targetRationale
  .
  "Writer/json boundary scenario uses typed writer contracts while keeping output behavior readable under failure.")
(maxRssMb . 512)
(rule . "GERBIL-SCHEME-AGENT-POLICY-013")
(purpose . "R013 writer-json boundary replaces manual JSON string assembly with explicit writer extension contracts.")
(regression_budget
  (parseMs 20)
  (policyMs 40)
  (scenarioMs 120)
  (maxFindings 4))

(observedTimings
  (collectProjectMs 8)
  (policyFindingsMs 6)
  (scenarioContextMs 4)
  (scenarioLearningMs 3))

(scenarioIntent
  (id writer-json-boundary)
  (policy R013)
  (mode reasoning-first)
  (source gerbil-v0.19-staging std/format/writer std/encoding/json/writer)
  (goal "Replace manual string JSON assembly with a writer/serializer boundary."))

(scenarioQualityAxes
  (writerExtensionBoundary
   (positive defwriter-ext writer.serialize writer.write-json-field)
   (negative string-append display scattered-separators))
  (jsonWriterBoundary
   (positive defjson-writer write-json-object write-json-slot)
   (negative manual-braces manual-commas manual-quotes))
  (performanceBoundary
   (positive buffered-writer typed-output)
   (negative repeated-intermediate-strings)))

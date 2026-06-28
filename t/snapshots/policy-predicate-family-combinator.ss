(policyScenario
 (id "predicate-family-combinator")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-016"
                   "src/orders/core.ss"
                   "src/orders/core.ss:6-20"
                   "predicate family over fact repeats field/role condition helpers; keep repair policy-driven, extract selector helpers or a bounded predicate combinator before editing for style or performance"))
         (profile ((styleGuide "predicate-family-combinator")
                   (subject "fact")
                   (predicateCount 3)
                   (fieldKeys ("role" "fields"))
                   (repeatedCallees ("hash-get" "equal?" "field-string"))
                   (referencePattern "gerbil-utils-predicate-combinator")
                   (referenceExamples
                    ("gerbil-utils/base.ss#lambda-match/lambda-ematch"
                     "gerbil-utils/base.ss#fun"
                     "gerbil-utils/base.ss#compose/rcompose"
                     "gerbil-utils/base.ss#cut/curry/rcurry"
                     "gerbil-utils/base.ss#ensure-function"
                     "gerbil-utils/generator.ss#generating-map/fold"))
                   (qualitySignals
                    ("small-selector-helper"
                     "lambda-match-destructuring"
                     "lambda-match-rewrite-opportunity"
                     "named-lambda-helper"
                     "expression-level-composition"
                     "predicate-combinator"
                     "function-pipeline-abstraction"
                     "generator-aware-transform"))
                   (repairStandard
                    "rewrite toward learned Gerbil predicate style: keep predicate names stable, extract role/field selector helpers, and compose small expression-returning predicates"))))
 (after (r016Findings ())))

(policyScenario
 (id "controlled-branch-shape")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-014"
                   "src/orders/core.ss"
                   "src/orders/core.ss:7-9"
                   "caller decode-order has repeated match branches; keep the repair policy-driven and prefer lambda-match/lambda-ematch, fun, or a bounded selector pipeline before editing for style or performance"))
         (shape ((caller "decode-order")
                 (shape "repeated-pattern-branch")
                 (matchCount 2)
                 (manualLoopCount 0)
                 (conditionalBranchCount 0)
                 (conditionalDispatchGate 4)
                 (evidence
                  "parser-owned controlFlowFacts role=pattern-branch, manual-loop bindingCount>=4, or conditional-branch count>=4")
                 (advice "do not refactor opportunistically; wait for this policy finding, preserve behavior, and use guide code for controlled branch shape")
                 (styleGuide "controlled-branch-shape")
                 (styleCommand
                  "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-014 --intent style")
                 (rewriteScope "same caller or extracted helper only")
                 (sourceBackedOwners
                  ("gerbil-utils/base.ss#lambda-match/lambda-ematch"
                   "gerbil-utils/base.ss#fun"
                   "gerbil-utils/base.ss#cut/curry/rcurry"
                   "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
                   "gerbil-utils/base.ss#case-lambda specializers"
                   "gerbil-utils/generator.ss#compose-backed-generating-map"))
                 (sourceBackedRepairCandidates
                  ("lambda-match/lambda-ematch for unary match destructuring"
                   "fun for reusable local named lambda boundaries"
                   "cut/curry/rcurry for first-class argument specialization"
                   "compose/rcompose/!>/!!> for reusable expression pipelines"
                   "case-lambda only when there are real arity specializations"
                   "plain named helpers only when no higher-order Gerbil idiom fits"))
                 (functionShape
                  "source-backed Gerbil idioms first: lambda-match/lambda-ematch for unary match destructuring, fun for reusable local lambdas, cut/curry/rcurry for specialization, compose/rcompose/!>/!!> for pipelines")
                 (expressionLevelRewrite
                  "turn repeated branch or dispatch shape into lambda-match/lambda-ematch, fun, cut/curry/rcurry, compose/rcompose/!>/!!>, fold/filter-map, generator combinator, or a named helper in that order of evidence"))))
 (after (r014Findings ())))

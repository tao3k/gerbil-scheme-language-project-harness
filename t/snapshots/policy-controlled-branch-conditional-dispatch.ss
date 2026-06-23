(policyScenario
 (id "controlled-branch-conditional-dispatch")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R014"
    "src/orders/core.ss"
    "src/orders/core.ss:9-18"
    "caller dispatch-order has nested conditional dispatch; keep the repair policy-driven, split native fast paths, sibling binary fallback, and source fallback into named helpers before editing for style or performance"))
  (shape
   ((caller "dispatch-order")
    (shape "nested-conditional-dispatch")
    (matchCount 0)
    (manualLoopCount 0)
    (conditionalBranchCount 4)
    (conditionalDispatchGate 4)
    (evidence
     "parser-owned controlFlowFacts role=pattern-branch, manual-loop bindingCount>=4, or conditional-branch count>=4")
    (advice
     "do not refactor opportunistically; wait for this policy finding, preserve behavior, and use guide code for controlled branch shape")
    (styleGuide "controlled-branch-shape")
    (styleCommand
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style")
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
 (after
  (r014Findings ())))

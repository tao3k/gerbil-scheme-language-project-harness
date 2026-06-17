(policyScenario
 (id "controlled-branch-shape")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R014"
    "src/orders/core.ss"
    "src/orders/core.ss:7-9"
    "caller decode-order has repeated match branches; keep the repair policy-driven, split nested branch logic into named helpers or a bounded selector pipeline before editing for style or performance"))
  (shape
   ((caller "decode-order")
    (shape "repeated-pattern-branch")
    (matchCount 2)
    (manualLoopCount 0)
    (evidence
     "parser-owned controlFlowFacts role=pattern-branch plus manual-loop bindingCount>=4")
    (advice
     "do not refactor opportunistically; wait for this policy finding, preserve behavior, and use guide code for controlled branch shape")
    (styleGuide "controlled-branch-shape")
    (styleCommand
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style")
    (rewriteScope "same caller or extracted helper only")
    (functionShape
     "small selector/predicate/helper first; keep match branches shallow and expression-returning")
    (expressionLevelRewrite
     "turn repeated match plus accumulator shape into a named predicate/mapper/reducer pipeline before changing behavior"))))
 (after
  (r014Findings ())))

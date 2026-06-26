(policyScenario
 (id "comment-quality")
 (before (finding ("GERBIL-SCHEME-AGENT-R015"
                   "src/orders/core.ss"
                   "src/orders/core.ss"
                   "1 key comment locations need engineering comments beyond typed contracts"))
         (comment ((styleGuide "engineering-comment-quality")
                   (evidenceSource "parser-owned commentQualityFacts.evidence")
                   (repairInstruction
                    "write adjacent engineering comment lines when parserEvidence needs them; concise prose, bullets, or Boundary/Invariant/Intent labels are all valid")
                   (repairOrder
                    "run after grouped structural/style repairs such as typed-combinator, controlled-branch, or predicate-family combinator fixes")
                   (expectedCommentPrefix ";;;")
                   (commentLinePolicy
                    "split multi-clause engineering rationale across adjacent comment lines when it improves confidence; do not squeeze rationale clauses into one semicolon-separated line")
                   (typedContractBoundary
                    "Scheme-native typed blocks describe algebraic shape only and may use adjacent multi-line contract blocks when needed")
                   (weakCommentCount 1)
                   (repairTargets ("src/orders/core.ss"))
                   (exampleTarget "src/orders/core.ss")
                   (exampleContext "module")
                   (exampleCommentKind "missing")
                   (exampleQuality "absent")
                   (exampleReasons ("missing-engineering-comment")))))
 (after (r015Findings ())))

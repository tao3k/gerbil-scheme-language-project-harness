(policyScenario
 (id "real-agent-basic-syntax")
 (before (findings
          (("GERBIL-SCHEME-AGENT-POLICY-009"
            "src/dashboard/workflow.ss"
            "src/dashboard/workflow.ss:19-27"
            "basic named-let/rest-accumulator loop looks like a redundant pure transform; rewrite toward Gerbil/Gambit idioms such as fold/filter-map, lambda-match/match, cut/curry/compose, case-lambda, or values/call-with-values unless parser facts show IO, stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
           ("GERBIL-SCHEME-AGENT-POLICY-014"
            "src/dashboard/workflow.ss"
            "src/dashboard/workflow.ss:33-41"
            "caller dispatch-dashboard has nested conditional dispatch; keep the repair policy-driven and choose source-backed Gerbil idioms such as fun, cut/curry/rcurry, compose/rcompose, or named fallback helpers before editing for style or performance")
           ("GERBIL-SCHEME-AGENT-POLICY-028"
            "src/dashboard/workflow.ss"
            "src/dashboard/workflow.ss:47-47"
            "POO loop loop repeatedly clones with .cc; prefer accumulating scalar state and applying one final .cc, or use .put! only when mutation is intentional")))
         (functional
          ((kind "named-let")
           (caller "score-events")
           (advice "replace basic Scheme scaffolding with parser-owned Gerbil/Gambit idioms for pure transforms")
           (basicSyntaxSmells
            ("named-let rest/accumulator traversal"
             "manual null?/car/cdr branch over a list"
             "threaded accumulator state without IO or control preservation"
             "anonymous list tuple projection where values/call-with-values would name the protocol"
             "nested conditional shape dispatch where match/lambda-match would expose the data shape"))
           (nativeRepairContract
            ("sequence traversal -> map/filter/filter-map/fold/foldl/foldr/andmap/ormap"
             "shape dispatch -> match/lambda-match"
             "arity specialization -> case-lambda"
             "partial application -> cut/cute/curry/rcurry/compose/!>/!!>"
             "tuple projection -> values/call-with-values"
             "state/control boundary -> parameterize/dynamic-wind or preserve named-let"))
           (designFeaturePriority
            ("prefer a semantic Gerbil/Gambit feature over a surface syntax rewrite"
             "make the data-flow shape visible in the expression body"
             "keep named-let only when recursion is the actual control model"
             "use the smallest idiom that removes accumulator and projection boilerplate"))
           (sequenceIdioms
            ("map"
             "filter"
             "filter-map"
             "append-map"
             "fold/foldl/foldr"
             "for/fold"))
           (predicateIdioms ("andmap/ormap" "every/any" "find/list-index"))
           (compositionIdioms
            ("cut/cute" "curry/rcurry" "compose/compose1" "!>/!!>"))
           (nativeLambdaIdioms
            ("fun" "lambda-match/λ-match" "λ" "case-lambda"))
           (typeclassIdioms
            ("gerbil-poo/fun.ss Category."
             "Functor."
             "ParametricFunctor."
             "Wrapper./Wrap."
             "methods.table protocol slots"))
           (builderIdioms ("with-list-builder"))
           (styleGuide "typed-combinator-style")
           (styleCommand
            "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
           (detectedControlContexts ())
           (keepNamedLetWhen
            "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
           (learnedFrom
            "gerbil:// and gerbil-utils/base.ss expose λ/lambda-match/compose/!>/curry/rcurry/fun for compact higher-order helpers; Gambit values/call-with-values and dynamic-wind keep tuple/control protocols explicit; gerbil-poo/fun.ss models Category./Functor./ParametricFunctor. algebra; table.ss methods.table shows protocol slots plus derived table/list/sexp/json/marshal capability; named let remains valid for C3 selection, reader IO, and coroutine control")))
         (branch ((caller "dispatch-dashboard")
                  (shape "nested-conditional-dispatch")
                  (matchCount 0)
                  (manualLoopCount 0)
                  (conditionalBranchCount 4)
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
 (after (r009Findings ()) (r014Findings ()) (r028Findings ())))

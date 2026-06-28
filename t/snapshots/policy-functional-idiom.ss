(policyScenario
 (id "functional-idiom")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-009"
                   "src/orders/core.ss"
                   "src/orders/core.ss:6-9"
                   "basic named-let/rest-accumulator loop looks like a redundant pure transform; rewrite toward Gerbil/Gambit idioms such as fold/filter-map, lambda-match/match, cut/curry/compose, case-lambda, or values/call-with-values unless parser facts show IO, stateful control flow, C3-style fixpoint selection, or generator/continuation driver"))
         (guidance
          ((kind "named-let")
           (caller "total")
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
            "gerbil:// and gerbil-utils/base.ss expose λ/lambda-match/compose/!>/curry/rcurry/fun for compact higher-order helpers; Gambit values/call-with-values and dynamic-wind keep tuple/control protocols explicit; gerbil-poo/fun.ss models Category./Functor./ParametricFunctor. algebra; table.ss methods.table shows protocol slots plus derived table/list/sexp/json/marshal capability; named let remains valid for C3 selection, reader IO, and coroutine control"))))
 (after (r009Findings ())))

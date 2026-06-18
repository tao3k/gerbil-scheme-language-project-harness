(policyScenario
 (id "functional-idiom")
 (before (finding ("GERBIL-SCHEME-AGENT-R009"
                   "src/orders/core.ss"
                   "src/orders/core.ss:6-9"
                   "named-let loop looks like a redundant pure transform; prefer for/fold, map/filter/filter-map/append-map, fold, predicate helpers, cut/curry/compose, or with-list-builder only when parser facts show no IO, stateful control flow, C3-style fixpoint selection, or generator/continuation driver"))
         (guidance
          ((kind "named-let")
           (caller "total")
           (advice "prefer parser-owned functional idioms for pure transforms")
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
            ".data/gerbil-utils/base.ss exposes λ/lambda-match/compose/!>/curry/rcurry/fun for compact higher-order helpers; .data/gerbil-poo/fun.ss models Category./Functor./ParametricFunctor. algebra; table.ss methods.table shows protocol slots plus derived table/list/sexp/json/marshal capability; named let remains valid for C3 selection, reader IO, and coroutine control"))))
 (after (r009Findings ())))

(policyScenario
 (id "case-lambda-function-factory")
 (before (finding ("GERBIL-SCHEME-AGENT-R013"
                   "src/orders/core.ss"
                   "src/orders/core.ss"
                   "Scheme source owner has 1 definitions but only 1 adjacent typed-combinator-style algebraic contracts; parser-owned quality facets require repair toward compact expression-level composition; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
         (style ((styleGuide "typed-combinator-style")
                 (expectedCommentShape
                  "adjacent Gerbil contract projection block such as ;; : (forall (a) (-> (-> a a Order) (List a) (List a) Order))")
                 (compositionShape
                  "Gerbil-native expression shape; prefer lambda-match/match for shape dispatch, cut/curry/rcurry for specialization, case-lambda for real arity boundaries, values/call-with-values for tuple projection, and map/filter/filter-map/fold/andmap/ormap for sequence transforms")
                 (functionShape
                  "single-purpose expression-returning helper; one visible data-flow shape per function")
                 (agentRepairStandard
                  "rewrite toward learned Gerbil/Gambit style: small algebraic helpers, lambda-match/match where shape is the boundary, cut/curry/case-lambda for specialization, values for tuple protocols, and minimal let*/mutation scaffolding")
                 (expressionLevelRewrite
                  "extract predicate/mapper/reducer helpers, then compose with lambda-match/match/cut/curry/case-lambda/values/filter-map/map/fold/andmap/ormap when behavior fits")
                 (definitionCount 1)
                 (typedCommentCount 1)
                 (missingTypedCommentCount 0)
                 (implementationEvidenceCount 4)
                 (qualityFacets
                  ("contract-valid"
                   "scheme-native-block"
                   "higher-order-transform"
                   "aligned"
                   "arity-bearing-definition"
                   "call-backed"
                   "higher-order-used"
                   "combinator-backed"
                   "lambda-local-abstraction"
                   "parameterized-transform"
                   "wrapper-lambda-drift"
                   "function-specialization-opportunity"))
                 (gerbilUtilsImplementationSignals
                  ("λ/lambda-match local destructuring"
                   "fun named lambda abstraction"
                   "!>/!!> pipeline"
                   "apply compose"
                   "cut/curry/rcurry"
                   "case-lambda arity specialization"
                   "match/lambda-match shape dispatch"
                   "values/call-with-values tuple projection"
                   "parameterize/dynamic-wind control boundary"
                   "syntax-case/syntax-rules hygienic macro boundary"
                   "map/filter/filter-map/fold"
                   "andmap/ormap/every/any predicate folds"
                   "with-list-builder"))
                 (generatorCombinatorSignals ())
                 (generatorContractTargets ())
                 (controlledMacroSyntaxSignals ())
                 (controlledMacroTargets ())
                 (typeclassAlgebraSignals ())
                 (typeclassAlgebraTargets ())
                 (gerbilContractProjectionSignals
                  ("legacy contracts split at top-level <-, not nested arrows"
                   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
                   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"))
                 (qualityFacetSteering
                  ("prefer small local lambda/function-factory helpers when the behavior is a reusable transform"
                   "keep lambda/lambda-match parameters meaningful and push repeated destructuring into named helpers"
                   "extract repeated wrapper lambdas into a named factory, case-lambda function factory, curry/rcurry specializer, or compose/rcompose pipeline"
                   "repair anonymous specialization by introducing one first-class helper boundary before changing call sites")))))
 (after (r013Findings ())))

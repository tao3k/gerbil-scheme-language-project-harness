(policyScenario
 (id "typeclass-algebra")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-013"
                   "src/orders/core.ss"
                   "src/orders/core.ss"
                   "Scheme source owner has 2 definitions but only 0 adjacent typed-combinator-style algebraic contracts; parser-owned quality facets require repair toward compact expression-level composition; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
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
                 (definitionCount 2)
                 (typedCommentCount 0)
                 (missingTypedCommentCount 1)
                 (implementationEvidenceCount 0)
                 (qualityFacets
                  ("anti-ai-scaffold-boundary"
                   "poo-typeclass-algebra-boundary"))
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
                 (typeclassAlgebraSignals
                  ("Category. compose/identity algebra"
                   "Functor. map/tap/ap algebra"
                   "Wrapper. wrap/unwrap/bind/map algebra"
                   "ParametricFunctor. higher-kinded adapter boundary"
                   "methods.io<-wrap lifts IO/JSON/bytes/marshal through wrap/unwrap"
                   "method bodies stay protocol-shaped instead of table-shaped"))
                 (typeclassAlgebraTargets ("OrderFunctor."))
                 (gerbilContractProjectionSignals
                  ("Scheme-native ;; : contract blocks preserve arrow structure without comment-arrow fallback"
                   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
                   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"))
                 (qualityFacetSteering
                  ("replace generated-looking protocol scaffolding with local adapter boundaries; use compose or define-type methods.* shape when representation steps are already proven"
                   "when POO facts expose typeclass/functor/wrapper options, model the implementation after gerbil-poo/fun.ss algebra instead of raw object adapters or ad hoc tables")))))
 (after (r013Findings
         (("GERBIL-SCHEME-AGENT-POLICY-013"
           "src/orders/core.ss"
           "src/orders/core.ss"
           "Scheme source owner has 2 definitions but only 1 adjacent typed-combinator-style algebraic contracts; parser-owned quality facets require repair toward compact expression-level composition; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches")))))

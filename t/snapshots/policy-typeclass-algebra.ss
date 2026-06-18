(policyScenario
 (id "typeclass-algebra")
 (before (finding ("GERBIL-SCHEME-AGENT-R013"
                   "src/orders/core.ss"
                   "src/orders/core.ss"
                   "Scheme source owner has 2 definitions but only 0 adjacent typed-combinator-style algebraic contracts; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
         (style ((styleGuide "typed-combinator-style")
                 (expectedCommentShape
                  "adjacent Gerbil contract projection block such as ;; : (forall (a) (-> (-> a a Order) (List a) (List a) Order))")
                 (compositionShape
                  "compact expression-level helper or combinator chain; prefer map/filter/fold/cut/curry/compose when behavior fits")
                 (functionShape
                  "single-purpose expression-returning helper; one visible data-flow shape per function")
                 (agentRepairStandard
                  "rewrite toward gerbil-utils style: small algebraic helpers, dense but readable composition, minimal let*/mutation scaffolding")
                 (expressionLevelRewrite
                  "extract predicate/mapper/reducer helpers, then compose with filter-map/map/fold/andmap/ormap/cut/curry/compose when behavior fits")
                 (definitionCount 2)
                 (typedCommentCount 0)
                 (missingTypedCommentCount 1)
                 (implementationEvidenceCount 0)
                 (qualityFacets ("poo-typeclass-algebra-boundary"))
                 (gerbilUtilsImplementationSignals
                  ("λ/lambda-match local destructuring"
                   "fun named lambda abstraction"
                   "!>/!!> pipeline"
                   "apply compose"
                   "cut/curry/rcurry"
                   "map/filter/filter-map/fold"
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
                   "method bodies stay protocol-shaped instead of table-shaped"))
                 (typeclassAlgebraTargets ("OrderFunctor."))
                 (gerbilContractProjectionSignals
                  ("legacy contracts split at top-level <-, not nested arrows"
                   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
                   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"))
                 (qualityFacetSteering
                  ("when POO facts expose typeclass/functor/wrapper options, model the implementation after gerbil-poo/fun.ss algebra instead of raw object adapters or ad hoc tables")))))
 (after (r013Findings ())))

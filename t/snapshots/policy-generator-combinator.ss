(policyScenario
 (id "generator-combinator")
 (before (finding ("GERBIL-SCHEME-AGENT-R013"
                   "src/orders/core.ss"
                   "src/orders/core.ss"
                   "Scheme source owner has 1 definitions but only 1 adjacent typed-combinator-style algebraic contracts; 1 public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments; parser-owned quality facets require repair toward compact expression-level composition; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
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
                 (definitionCount 1)
                 (typedCommentCount 1)
                 (missingTypedCommentCount 0)
                 (implementationEvidenceCount 0)
                 (qualityFacets
                  ("contract-valid"
                   "legacy-contract"
                   "grouped-transform"
                   "aligned"
                   "arity-bearing-definition"
                   "manual-loop-drift"
                   "combinator-candidate"
                   "over-abstracted-contract-risk"
                   "legacy-typed-contract"
                   "gerbil-contract-projection-migration"
                   "control-flow:manual-loop"
                   "generator-combinator-boundary"))
                 (gerbilUtilsImplementationSignals
                  ("λ/lambda-match local destructuring"
                   "fun named lambda abstraction"
                   "!>/!!> pipeline"
                   "apply compose"
                   "cut/curry/rcurry"
                   "map/filter/filter-map/fold"
                   "with-list-builder"))
                 (generatorCombinatorSignals
                  ("Generating contract projection"
                   "generating<-list source adapter"
                   "generating-map transform"
                   "generating-fold reducer"
                   "generating-partition split"
                   "generating-merge priority merge"
                   "generating<-cothread continuation bridge"))
                 (generatorContractTargets ("generated-total"))
                 (controlledMacroSyntaxSignals ())
                 (controlledMacroTargets ())
                 (typeclassAlgebraSignals ())
                 (typeclassAlgebraTargets ())
                 (gerbilContractProjectionSignals
                  ("legacy contracts split at top-level <-, not nested arrows"
                   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
                   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"))
                 (qualityFacetSteering
                  ("replace manual loops with map/filter/filter-map/fold pipelines when parser facts show no IO/state/generator witness"
                   "replace abstract grouped contracts with concrete domain/result names or add parser-owned callsite evidence"
                   "when contracts mention Generating, prefer gerbil-utils/generator.ss combinators such as generating-map, generating-fold, generating-partition, and generating-merge before hand-written producer loops")))))
 (after (r013Findings ())))

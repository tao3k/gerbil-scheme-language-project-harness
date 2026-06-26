(policyScenario
 (id "controlled-macro-syntax")
 (before (finding ("GERBIL-SCHEME-AGENT-R013"
                   "src/macros/core.ss"
                   "src/macros/core.ss"
                   "Scheme source owner has 1 definitions but only 0 adjacent typed-combinator-style algebraic contracts; 1 public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
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
                 (typedCommentCount 0)
                 (missingTypedCommentCount 1)
                 (implementationEvidenceCount 0)
                 (qualityFacets ("controlled-macro-syntax-boundary"))
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
                 (controlledMacroSyntaxSignals
                  ("syntax-case/with-syntax transformer shape"
                   "syntax-rules thin macro DSL"
                   "hygienic macro boundary"
                   "stx-lambda or def-stx helper boundary"
                   "macro syntax stays a thin hygienic syntax wrapper"
                   "runtime behavior remains in ordinary helpers"
                   "docs explain the expansion contract and example result"))
                 (controlledMacroTargets ("with-order-field"))
                 (typeclassAlgebraSignals ())
                 (typeclassAlgebraTargets ())
                 (gerbilContractProjectionSignals
                  ("Scheme-native ;; : contract blocks preserve arrow structure without comment-arrow fallback"
                   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
                   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"))
                 (qualityFacetSteering
                  ("when parser facts show macro owners, use upstream Gerbil macro-library idioms; keep syntax wrappers thin and hygienic, and push reusable runtime behavior into ordinary helpers")))))
 (after (r013Findings ())))

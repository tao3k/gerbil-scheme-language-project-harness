(policyScenario
 (id "typed-combinator-style")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R013"
    "src/orders/core.ss"
    "src/orders/core.ss"
    "Scheme source owner has 2 definitions but only 0 adjacent typed-combinator-style algebraic contracts; 2 public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
  (style
   ((styleGuide "typed-combinator-style")
    (expectedCommentShape
     "adjacent Scheme-native typed block such as ;; : (forall (a) (-> (-> a a Order) (List a) (List a) Order))")
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
    (missingTypedCommentCount 2)
    (implementationEvidenceCount 0)
    (qualityFacets ())
    (qualityFacetSteering ()))))
 (after
  (r013Findings ())))

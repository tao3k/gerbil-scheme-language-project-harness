(policyScenario
 (id "destructuring-combinator-boundary")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R013"
    "src/events/core.ss"
    "src/events/core.ss"
    "Scheme source owner has 3 definitions but only 3 adjacent typed-combinator-style algebraic contracts; parser-owned expression-level implementation evidence covers 0/3 arity-bearing definitions, below minimum 2; parser-owned quality facets require repair toward compact expression-level composition; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
  (destructuring
   ((qualityFacets
     ("contract-valid"
      "legacy-contract"
      "domain-transform"
      "input-count-mismatch"
      "arity-bearing-definition"
      "call-backed"
      "combinator-candidate"
      "legacy-typed-contract"
      "gerbil-contract-projection-migration"
      "control-flow:conditional-branch"
      "destructuring-combinator-boundary"))
    (compositionShape
     "Gerbil-native expression shape; prefer lambda-match/match for shape dispatch, cut/curry/rcurry for specialization, case-lambda for real arity boundaries, values/call-with-values for tuple projection, and map/filter/filter-map/fold/andmap/ormap for sequence transforms")
    (destructuringBoundarySignals
     ("replace repeated car/cdr/assq scaffolding with a named selector or match boundary"
      "prefer native match/apply destructuring when it removes runtime probing"
      "use syntax-local metadata lookup when the shape is known at expansion time"
      "keep match-specific macro extension local and early-failing; do not invent broad macro layers"
      "use lambda-match or match when pair shape is the actual interface"
      "use local slot/lens helpers when repeated destructuring is object-slot access"
      "keep temporary let bindings only when they name a real domain boundary"))
    (destructuringBoundaryTargets
     ("summarize-agent-event" "route-agent-event" "event-archive-key")))))
 (after (r013Findings ())))

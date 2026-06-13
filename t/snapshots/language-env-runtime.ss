(languageEvidenceSearch
 (namespace "env")
 (authority "active-runtime")
 (evidenceGrade "fact")
 (query "gxi")
 (facts
  ((languageEvidenceFact
    (id "active-gerbil-runtime")
    (summary "Active Gerbil runtime discovered from the executing provider process.")
    (evidenceGrade "fact")
    (witness "gerbil-home-gxi-gsc-load-path-resolved")
    (next "search env load-path")
    (details
     (runtimeResolved #t)
     (gxiExists #t)
     (gscExists #t)
     (loadPathKnown #t))
    (selectors ())
    (agentScenario "agent-needs-active-gerbil-runtime-before-import-or-macro-claims")
    (intent "discover-active-gxi-gsc-and-load-path-before-writing-gerbil-code")
    (failureCases
     ((failureCase
       (id "stale-doc-runtime")
       (risk "agent-trusts-online-gerbil-version-instead-of-active-gxi")
       (correction "query-search-env-before-version-or-import-guidance"))
      (failureCase
       (id "global-path-hardcoding")
       (risk "agent-copies-user-machine-path-into-project-docs-or-code")
       (correction "treat-runtime-path-as-evidence-not-project-config"))))
    (qualitySignals ("active-gxi" "active-gsc" "runtime-load-path")))))
 (next "search env load-path"))

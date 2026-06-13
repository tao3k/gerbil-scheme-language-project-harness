(compareSearch
 (namespace "compare")
 (authority "active-runtime-vs-documented")
 (evidenceGrade "fact")
 (quality "verified")
 (query "env active documented")
 (comparisons
  ((comparison
    (id "env-active-documented")
    (summary "Active Gerbil runtime evidence is authoritative over documented or remembered runtime claims.")
    (evidenceGrade "fact")
    (witness "active-runtime-beats-documented-memory")
    (next "search env gxi load-path")
    (left
     (kind "active-runtime")
     (gxiResolved #t)
     (gscResolved #t))
    (right
     (kind "documented-runtime")
     (source "documentation-or-model-memory")
     (status "non-authoritative"))
    (result "active-runtime-authoritative")
    (agentScenario "agent-needs-to-choose-active-gxi-over-documented-or-remembered-version")
    (intent "compare-active-runtime-before-answering-version-sensitive-gerbil-questions")
    (failureCases
     ((failureCase
       (id "documented-version-wins")
       (risk "agent-follows-documentation-or-model-memory-over-active-gxi")
       (correction "query-compare-env-active-documented-before-version-sensitive-guidance"))
      (failureCase
       (id "compare-leaks-local-path")
       (risk "agent-copies-active-runtime-absolute-path-into-docs-or-code")
       (correction "compare-output-must-report-resolution-status-without-local-paths"))))
    (qualitySignals ("active-runtime-fact"
                     "no-memory"
                     "path-free-compare-output")))))
 (missing ())
 (witness "active-runtime-beats-documented-memory")
 (next "search env gxi load-path"))

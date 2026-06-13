;;; -*- Gerbil -*-
;;; Stable compare facts for active Gerbil runtime evidence.

(import :language/evidence
        :std/srfi/13)

(export compare-facts
        matching-compare-facts
        compare-fact-json)

(def (compare-facts)
  (let* ((runtime-fact (car (active-runtime-facts)))
         (details (hash-get runtime-fact 'details))
         (version-string (gerbil-system-version-string)))
    [(hash (id "env-active-documented")
           (summary "Active Gerbil runtime evidence is authoritative over documented or remembered runtime claims.")
           (evidenceGrade "fact")
           (witness "active-runtime-beats-documented-memory")
           (next "search env gxi load-path")
           (terms ["compare" "env" "active" "documented" "runtime" "gxi"
                   "version" version-string])
           (left (hash (kind "active-runtime")
                       (systemVersion version-string)
                       (gxiResolved (hash-get details 'gxiExists))
                       (gscResolved (hash-get details 'gscExists))))
           (right (hash (kind "documented-runtime")
                        (source "documentation-or-model-memory")
                        (status "non-authoritative")))
           (result "active-runtime-authoritative")
           (agentScenario "agent-needs-to-choose-active-gxi-over-documented-or-remembered-version")
           (intent "compare-active-runtime-before-answering-version-sensitive-gerbil-questions")
           (qualitySignals ["active-runtime-fact"
                            "no-memory"
                            "path-free-compare-output"])
           (failureCases
            [(hash (id "documented-version-wins")
                   (risk "agent-follows-documentation-or-model-memory-over-active-gxi")
                   (correction "query-compare-env-active-documented-before-version-sensitive-guidance"))
             (hash (id "compare-leaks-local-path")
                   (risk "agent-copies-active-runtime-absolute-path-into-docs-or-code")
                   (correction "compare-output-must-report-resolution-status-without-local-paths"))]))]))

(def (matching-compare-facts terms)
  (let (facts (compare-facts))
    (if (null? terms)
      facts
      (filter (cut compare-fact-matches-terms? <> terms) facts))))

(def (compare-fact-matches-terms? fact terms)
  (ormap (lambda (term)
           (ormap (cut string-contains <> term)
                  (hash-get fact 'terms)))
         terms))

(def (compare-fact-json fact)
  (hash (id (hash-get fact 'id))
        (summary (hash-get fact 'summary))
        (evidenceGrade (hash-get fact 'evidenceGrade))
        (witness (hash-get fact 'witness))
        (next (hash-get fact 'next))
        (left (hash-get fact 'left))
        (right (hash-get fact 'right))
        (result (hash-get fact 'result))
        (agentScenario (hash-get fact 'agentScenario))
        (intent (hash-get fact 'intent))
        (qualitySignals (hash-get fact 'qualitySignals))
        (failureCases (hash-get fact 'failureCases))))

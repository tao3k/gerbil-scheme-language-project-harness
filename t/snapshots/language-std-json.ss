(languageEvidenceSearch
 (namespace "std")
 (authority "standard-library")
 (evidenceGrade "fact")
 (query "json")
 (facts
  ((languageEvidenceFact
    (id "std/text/json")
    (summary "Gerbil JSON parsing is available through :std/text/json; import read-json with only-in when the harness needs machine packet validation.")
    (evidenceGrade "fact")
    (witness "provider-imports-:std/text/json")
    (next "search std json")
    (details
     (module ":std/text/json")
     (capabilities ("read-json"))
     (minimalImport "(import (only-in :std/text/json read-json))"))
    (selectors ())
    (agentScenario "agent-needs-json-packet-validation-without-python-parser")
    (intent "use-gerbil-std-text-json-read-json-with-only-in")
    (failureCases
     ((failureCase
       (id "foreign-json-parser")
       (risk "agent-adds-python-or-shell-json-parser-for-gerbil-tests")
       (correction "use-read-json-from-std-text-json"))
      (failureCase
       (id "broad-json-import")
       (risk "agent-imports-more-json-surface-than-the-test-needs")
       (correction "use-only-in-std-text-json-read-json"))))
    (qualitySignals ("provider-imports-std-module"
                     "read-json-capability"
                     "only-in-minimal-import")))))
 (next "search std json"))

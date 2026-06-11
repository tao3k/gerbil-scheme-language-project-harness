;;; -*- Gerbil -*-
(import :std/test
        :unit/schema/bundle)
(export schema-test)

(def schema-test
  (test-suite "gerbil scheme schema bundle"
    (test-case "tracked schema files exist locally"
      (check (missing-schema-files +schema-files+) => '()))
    (test-case "local schema refs resolve without remote fetch"
      (let (refs (schema-ref-closure))
        (check refs => +local-schema-refs+)
        (check (missing-schema-files refs) => '())))))

;;; -*- Gerbil -*-
;;; gerbil-utils source profile policy tests.

(import :std/test
        :policy/gerbil-utils-source)

(export gerbil-utils-source-policy-test)

;; PolicyTest
(def gerbil-utils-source-policy-test
  (test-suite "gerbil-utils source profile policy"
    (test-case "source profiles expose stable owner and quality metadata"
      (let ((predicate (gerbil-utils-source-details 'predicate-combinator))
            (sequence (gerbil-utils-source-details 'sequence-protocol))
            (macro (gerbil-utils-source-details 'macro-helper)))
        (check (hash-get predicate 'sourcePattern)
               => "gerbil-utils-predicate-combinator")
        (check (hash-get predicate 'sourceOwners)
               => ["gerbil-utils/base.ss#compose"
                   "gerbil-utils/base.ss#cut/curry/rcurry"
                   "gerbil-utils/base.ss#ensure-function"
                   "gerbil-utils/generator.ss#generating-map/fold"])
        (check (hash-get sequence 'qualitySignals)
               => ["named-traversal-protocol"
                   "map-fold-boundary"
                   "observable-cursor-state"])
        (check (hash-get macro 'sourcePattern)
               => "gerbil-utils-controlled-macro-helper")
        (check (hash-get macro 'qualitySignals)
               => ["controlled-macro-helper"
                   "syntax-case-with-local-parser"
                   "thin-syntax-bridge"])))
    (test-case "unknown source profiles fall back to default exemplar metadata"
      (let ((details (gerbil-utils-source-details 'unknown-quality-pattern)))
        (check (hash-get details 'sourcePattern)
               => "gerbil-utils-quality-pattern")
        (check (hash-get details 'sourceOwners)
               => ["gerbil-utils/base.ss"
                   "gerbil-utils/generator.ss"
                   "gerbil-utils/syntax.ss"])))))

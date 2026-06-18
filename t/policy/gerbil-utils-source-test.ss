;;; -*- Gerbil -*-
;;; gerbil-utils source profile policy tests.

(import :std/test
        :policy/detection
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
                   "thin-syntax-bridge"])
        (check (hash-get predicate 'profilePrecedence)
               => ["gerbil-utils-predicate-combinator"
                   "gerbil-utils-source-base"])))
    (test-case "unknown source profiles fall back to default exemplar metadata"
      (let ((details (gerbil-utils-source-details 'unknown-quality-pattern)))
        (check (hash-get details 'sourcePattern)
               => "gerbil-utils-quality-pattern")
        (check (hash-get details 'sourceOwners)
               => ["gerbil-utils/base.ss"
                   "gerbil-utils/generator.ss"
                   "gerbil-utils/syntax.ss"])
        (check (hash-get details 'profilePrecedence)
               => ["gerbil-utils-quality-pattern"
                   "gerbil-utils-source-base"])))
    (test-case "source detection overlays expose POO profile precedence"
      (let* ((projection-evidence
              (lambda (_subject)
                (evidence-group "projection-shape" 1 "sample.ss:3-8")))
             (prototype
              (detection-prototype-extend
               +threshold-detection-prototype+
               (gerbil-utils-source-detection-overlay 'projection-builder)
               (detection-prototype
                "projection-source-backed-threshold"
                'threshold
                [projection-evidence]
                1
                '()
                "projection source profile survives detector composition")))
             (result (run-detection-prototype 'subject prototype))
             (details (detection-result-details result)))
        (check (hash-get details 'detectionSourcePattern)
               => "gerbil-utils-projection-builder")
        (check (hash-get details 'detectionSourceProfilePrecedence)
               => ["gerbil-utils-projection-builder"
                   "gerbil-utils-source-base"])
        (check (hash-get details 'detectionSourceProfileComposition)
               => "policy/prototype slot-profile + POO/C3 source-profile overlay")))))

;;; -*- Gerbil -*-
;;; gerbil-utils quality reference policy tests.

(import :std/test
        :policy/detection
        :policy/gerbil-utils-source)

(export gerbil-utils-source-policy-test)

;; PolicyTest
(def gerbil-utils-source-policy-test
  (test-suite "gerbil-utils quality reference policy"
    (test-case "quality references expose stable examples and quality metadata"
      (let ((predicate (gerbil-utils-source-details 'predicate-combinator))
            (higher-order
             (gerbil-utils-source-details 'higher-order-expression))
            (sequence (gerbil-utils-source-details 'sequence-protocol))
            (generator (gerbil-utils-source-details 'generator-control))
            (protocol
             (quality-reference-details 'protocol-serialization-boundary))
            (slot-lens (quality-reference-details 'slot-lens-boundary))
            (exception
             (quality-reference-details
              'exception-continuation-boundary))
            (stateful (gerbil-utils-source-details 'stateful-structure))
            (macro (gerbil-utils-source-details 'macro-helper)))
        (check (hash-get predicate 'referencePattern)
               => "gerbil-utils-predicate-combinator")
        (check (not (not (member "gerbil-utils/base.ss#compose/rcompose"
                                 (hash-get predicate 'referenceExamples))))
               => #t)
        (check (not (not (member "gerbil-utils/base.ss#cut/curry/rcurry"
                                 (hash-get predicate 'referenceExamples))))
               => #t)
        (check (not (not (member "generator-aware-transform"
                                 (hash-get predicate 'qualitySignals))))
               => #t)
        (check (hash-get higher-order 'referencePattern)
               => "gerbil-utils-higher-order-expression")
        (check (not (not (member "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                                 (hash-get higher-order 'referenceExamples))))
               => #t)
        (check (not (not (member "cut-prefix-predicate"
                                 (hash-get higher-order 'qualitySignals))))
               => #t)
        (check (hash-get sequence 'qualitySignals)
               => ["named-traversal-protocol"
                   "map-fold-boundary"
                   "observable-cursor-state"])
        (check (hash-get generator 'referencePattern)
               => "gerbil-utils-generator-control")
        (check (hash-get generator 'referenceExamples)
               => ["gerbil-utils/generator.ss#generating<-for-each"
                   "gerbil-utils/generator.ss#yield-continuation-boundary"
                   "gerbil-utils/generator.ss#unexpected-yield"
                   "gerbil-utils/generator.ss#eof!"
                   "gerbil-utils/generator.ss#list<-generating"
                   "gerbil-utils/generator.ss#generating<-cothread"])
        (check (not (not (member "push-pull-control-inversion"
                                 (hash-get generator 'qualitySignals))))
               => #t)
        (check (not (not (member "call/cc-yield-boundary"
                                 (hash-get generator 'qualitySignals))))
               => #t)
        (check (hash-get protocol 'referencePattern)
               => "protocol-serialization-boundary")
        (check (not (not (member "gerbil-poo/io.ss#methods.marshal<-bytes"
                                 (hash-get protocol 'referenceExamples))))
               => #t)
        (check (not (not (member "self-delimited-marshal-boundary"
                                 (hash-get protocol 'qualitySignals))))
               => #t)
        (check (not (not (member "bytes-non-self-delimited-boundary"
                                 (hash-get protocol 'qualitySignals))))
               => #t)
        (check (hash-get slot-lens 'referencePattern)
               => "slot-lens-boundary")
        (check (not (not (member "gerbil-poo/mop.ss#Lens.modify"
                                 (hash-get slot-lens 'referenceExamples))))
               => #t)
        (check (not (not (member "gerbil-poo/mop.ss#slot-lens"
                                 (hash-get slot-lens 'referenceExamples))))
               => #t)
        (check (not (not (member "slot-descriptor-boundary"
                                 (hash-get slot-lens 'qualitySignals))))
               => #t)
        (check (not (not (member "local-lens-helper"
                                 (hash-get slot-lens 'qualitySignals))))
               => #t)
        (check (hash-get exception 'referencePattern)
               => "exception-continuation-boundary")
        (check (not (not (member "gerbil-utils/exception.ss#with-catch/cont"
                                 (hash-get exception 'referenceExamples))))
               => #t)
        (check (not (not (member "gerbil-utils/exception.ss#call-with-logged-exceptions"
                                 (hash-get exception 'referenceExamples))))
               => #t)
        (check (not (not (member "handler-restoration-boundary"
                                 (hash-get exception 'qualitySignals))))
               => #t)
        (check (not (not (member "re-raise-after-logging"
                                 (hash-get exception 'qualitySignals))))
               => #t)
        (check (hash-get stateful 'referencePattern)
               => "gerbil-utils-stateful-structure")
        (check (hash-get stateful 'referenceExamples)
               => ["gerbil-utils/stateful-avl-map.ss#avl-map-update-height!"
                   "gerbil-utils/stateful-avl-map.ss#avl-map-rotate-left!/right!"
                   "gerbil-utils/stateful-avl-map.ss#avl-map-balance!"
                   "gerbil-utils/stateful-avl-map.ss#avl-map-put!/remove!"
                   "gerbil-utils/stateful-avl-map.ss#generating<-avl-map"
                   "gerbil-utils/stateful-avl-map.ss#table<-avl-map/alist<-avl-map"])
        (check (not (not (member "bounded-mutable-invariant"
                                 (hash-get stateful 'qualitySignals))))
               => #t)
        (check (not (not (member "generator-adapter-boundary"
                                 (hash-get stateful 'qualitySignals))))
               => #t)
        (check (hash-get macro 'referencePattern)
               => "gerbil-utils-controlled-macro-helper")
        (check (not (not (member "macro-hygiene-boundary"
                                 (hash-get macro 'qualitySignals))))
               => #t)
        (check (not (not (member "syntax-rules-thin-dsl"
                                 (hash-get macro 'qualitySignals))))
               => #t)
        (check (hash-get predicate 'profilePrecedence)
               => ["gerbil-utils-predicate-combinator"
                   "gerbil-utils-source-base"])))
    (test-case "unknown quality references fall back to default exemplar metadata"
      (let ((details (gerbil-utils-source-details 'unknown-quality-pattern)))
        (check (hash-get details 'referencePattern)
               => "gerbil-utils-quality-pattern")
        (check (hash-get details 'referenceExamples)
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

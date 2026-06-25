;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style scenario control runtime policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :std/sort
        :commands/check
        :parser/facade
        :policy/agent-style
        :policy/facade
        :policy/gxtest
        :scenario/policy
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-style-support)
(export agent-style-scenario-control-runtime-policy-test)

;; PolicyTest
(def agent-style-scenario-control-runtime-policy-test
  (test-suite "gerbil scheme harness agent style scenario control runtime policy"
(test-case "agent policy validates compiler method-pass scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "compiler-method-pass-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference
                  (hash-get details 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "compiler-method-pass-boundary"
             "compiler-method-pass-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "harness-self-apply"]
             ["compiler-method-pass-boundary"
              "method-table-pass-boundary"
              "gerbil-gambit-native-idiom"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "method-table lambda drift to compiler-style pass handlers")
            (check (agent-style-member?
                    "method-table-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-compiler-method-pass-boundary")
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/method.ss#defcompile-method"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "method-table-pass-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "ast-case-shape-dispatch"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "repair method-table lambdas by extracting slot-shaped helpers, compiler-style AST pass handlers, or cut/curry/compose adapters while preserving the receiver/protocol boundary"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates exception continuation scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "exception-continuation-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "exception-continuation-boundary"
             "exception-continuation-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["exception-continuation-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "exception-continuation-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "log exception context before re-raising"
                    (hash-get details 'exceptionContinuationBoundarySignals))
                   => #t)
            (check (hash-get details
                             'exceptionContinuationBoundaryTargets)
                   => ["run-checked"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 2))))
(test-case "agent policy validates higher-order composition scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "higher-order-composition-performance"))
                 (result (hash-get context 'result))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (agent-style-check-r013-scenario!
             context
             "higher-order-composition-performance"
             "higher-order-composition")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["higher-order-composition" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "wrapper lambda to composition boundary")
            (check (agent-style-member?
                    "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "cut-prefix-predicate"
                    (hash-get benchmark-contract 'expectedQualitySignals))
                   => #t)
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-higher-order-expression")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#left-to-right"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "cut-prefix-predicate"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "thin-wrapper-elimination"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member? "function-composition" higher-order-roles)
                   => #t)))
(test-case "agent policy validates case-lambda function factory scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "case-lambda-function-factory"))
                 (result (hash-get context 'result))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (agent-style-check-r013-scenario!
             context
             "case-lambda-function-factory"
             "case-lambda-function-factory")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["case-lambda-function-factory" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "case-lambda arity-specialized function factory")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#case-lambda specializers"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-abstraction"
                    (hash-get benchmark-contract 'expectedQualitySignals))
                   => #t)
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-higher-order-expression")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#case-lambda specializers"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-abstraction"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-function"
                    higher-order-roles)
                   => #t)))
  ))

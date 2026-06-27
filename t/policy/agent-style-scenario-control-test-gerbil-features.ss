;;; -*- Gerbil -*-
;;; Gerbil feature scenario control policy.

(import :std/test
        :policy/agent-style-support)
(export agent-style-scenario-control-gerbil-features-policy-test)

;; PolicyTest
(def agent-style-scenario-control-gerbil-features-policy-test
  (test-suite "agent style Gerbil feature scenario control policy"
(test-case "agent policy validates phase-aware macro boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "phase-aware-macro-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "phase-aware-macro-boundary"
             "phase-aware-macro-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://README.md"
              "gerbil://gerbil/expander/top.ss"
              "gerbil://gerbil/expander/core.ss"]
             ["meta-syntactic-tower"
              "phase-aware-macro-boundary"
              "controlled-macro-syntax"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "phase/context macro parsing split from runtime helper generation")
            (check (agent-style-member?
                    "phase-aware-macro-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "meta-syntactic-tower-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "split phase/context parsing from runtime helper generation"
                    (hash-get details 'phaseAwareMacroBoundarySignals))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-phase-aware-macro-boundary")
            (check (agent-style-member?
                    "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "runtime-helper-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when one owner mixes meta-syntactic tower, phase/context state, transformer parsing, expansion, and runtime helpers, split phase-aware macro parsing from ordinary runtime helpers and document the expansion contract"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates controlled macro syntax scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "controlled-macro-syntax"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference
                  (hash-get details 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "controlled-macro-syntax"
             "macro-hygiene")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["macro-hygiene-boundary"
              "scoped-expander-state-boundary"
              "source-aware-syntax-error"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "scoped expander state and controlled macro syntax boundary")
            (check (agent-style-member?
                    "controlled-macro-syntax-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "syntax-case/with-syntax transformer shape"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (agent-style-member?
                    "hygienic macro boundary"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (agent-style-member?
                    "parameterize phase/context state instead of mutating global macro state"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (agent-style-member?
                    "typed context records for macro/import/export state"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (agent-style-member?
                    "raise-syntax-error keeps source-aware failure paths"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (hash-get details 'controlledMacroTargets)
                   => ["with-order-field"])
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-controlled-macro-helper")
            (check (agent-style-member?
                    "gerbil://gerbil/expander/core.ss#current-expander-context"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://gerbil/expander/module.ss#core-expand-module-begin"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil-utils/autocurry.ss#syntax-rules"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/method.ss#ast-case-with-syntax-map-cut"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "macro-hygiene-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "parameterized-expander-state"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "typed-context-record-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "with-syntax-reconstruction-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)))
(test-case "agent policy validates SSXI optimizer metadata scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "ssxi-optimizer-metadata-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "ssxi-optimizer-metadata-boundary"
             "ssxi-optimizer-metadata-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://gerbil/compiler/ssxi.ss"
              "gerbil://gerbil/builtin-inline-rules.ssxi.ss"
              "gerbil://gerbil/compiler/optimize-call.ss"]
             ["ssxi-optimizer-metadata-boundary"
              "direct-call-shape"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "SSXI metadata and inline-rule visibility for direct primitive calls")
            (check (agent-style-member?
                    "ssxi-optimizer-metadata-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "optimizer-metadata-contract"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "keep SSXI metadata adjacent to the primitive boundary"
                    (hash-get details
                              'ssxiOptimizerMetadataBoundarySignals))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-ssxi-optimizer-metadata-boundary")
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "unchecked-call-visibility"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when one owner mixes SSXI metadata, inline rules, optimizer assumptions, primitive calls, and dynamic apply, keep metadata adjacent to the direct primitive boundary so unchecked-call and inline-rule visibility stays compiler-owned"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates actor runtime boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "actor-runtime-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "actor-runtime-boundary"
             "actor-runtime-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://std/actor-v18/executor.ss"
              "gerbil://std/actor-v18/server.ss"
              "gerbil://gerbil/runtime/control.ss"]
             ["actor-runtime-boundary"
              "mailbox-protocol-boundary"
              "runtime-control"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "actor mailbox protocol and lifecycle helper boundary")
            (check (agent-style-member?
                    "actor-runtime-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "mailbox-protocol-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "split actor spawn, mailbox send/receive, and shutdown boundaries"
                    (hash-get details 'actorRuntimeBoundarySignals))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-actor-runtime-boundary")
            (check (agent-style-member?
                    "gerbil://std/actor-v18/server.ss#actor-server-loop"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "actor-parameter-propagation"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when one owner mixes actor spawn, mailbox send/receive, shutdown, supervision, and parameters, split the actor runtime protocol into explicit mailbox, lifecycle, and parameter-propagation helpers"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates MOP C3 linearization boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "mop-c3-linearization-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "mop-c3-linearization-boundary"
             "mop-c3-linearization-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://gerbil/runtime/c3.ss#c4-linearize"
              "gerbil://gerbil/runtime/c3.ss#merge-sis!"
              "gerbil://gerbil/runtime/interface.ss#interface-descriptor"]
             ["mop-c3-linearization-boundary"
              "c3-precedence-boundary"
              "mop-descriptor-boundary"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "C3 precedence-list boundary and MOP descriptor helpers")
            (check (agent-style-member?
                    "mop-c3-linearization-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "c3-precedence-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "separate MOP descriptors from C3 precedence-list merging"
                    (hash-get details 'mopC3LinearizationBoundarySignals))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-runtime-c3-linearization-boundary")
            (check (agent-style-member?
                    "gerbil://gerbil/runtime/c3.ss#c4-linearize"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "c3-precedence-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when one owner mixes MOP descriptors, class/superclass shape, C3 precedence, tail merging, and compatibility checks, split descriptor construction from linearization merge helpers"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
  ))

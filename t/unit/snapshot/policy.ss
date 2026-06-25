;;; -*- Gerbil -*-
;;; Policy snapshot projection helpers.
;;; Scenario execution stays in :scenario/policy; this owner only normalizes
;;; finding details into stable snapshot data.

(import :parser/facade
        :policy/facade
        :scenario/policy
        :snapshot/facade
        :std/test
        :types/facade
        :unit/policy/poo-scenarios)

(export macro-controlled-helper-policy-snapshot
        functional-idiom-policy-snapshot
        generator-combinator-policy-snapshot
        controlled-macro-syntax-policy-snapshot
        typeclass-algebra-policy-snapshot
        controlled-branch-shape-policy-snapshot
        controlled-branch-conditional-dispatch-policy-snapshot
        typed-combinator-style-policy-snapshot
        case-lambda-function-factory-policy-snapshot
        comment-quality-policy-snapshot
        harness-dependency-policy-application-policy-snapshot
        harness-dependency-policy-disable-requires-explanation-policy-snapshot
        predicate-family-combinator-policy-snapshot
        build-support-shell-template-policy-snapshot
        package-build-shell-pipeline-policy-snapshot
        package-build-canonical-shape-policy-snapshot
        package-build-std-build-script-policy-snapshot
        package-build-std-make-ssi-policy-snapshot
        poo-prototype-fixed-point-policy-snapshot
        poo-guidance-corpus-policy-snapshot
        dependency-protocol-adapter-policy-snapshot
        dependency-manual-object-adapter-policy-snapshot
        check-policy-snapshot-fixtures)
;; Snapshot
(def (downstream-poo-agent-policy-snapshot)
  (write-downstream-poo-agent-project ".run/snapshot-policy-downstream-poo-agent")
  (let* ((index (collect-project ".run/snapshot-policy-downstream-poo-agent"))
         (findings (run-agent-policy index)))
    (list 'policyScenario
          (list 'id "downstream-poo-agent")
          (list 'findings (map finding-snapshot findings)))))

;; Snapshot
(def (poo-prototype-fixed-point-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "poo-prototype-fixed-point"
           "t/scenarios/policy/poo-prototype-fixed-point"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R026"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R026")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot-copy before-finding))
                (list 'guidance
                      (list
                       (list 'mode (hash-get before-details 'guidanceMode))
                       (list 'trigger (hash-get before-details 'trigger))
                       (list 'allowedUse (hash-get before-details 'allowedUse))
                       (list 'repairShape (hash-get before-details 'repairShape))
                       (list 'docsPath (hash-get before-details 'docsPath))
                       (list 'preferredSyntax
                             (hash-get before-details 'preferredSyntax)))))
          (list 'after
                (list 'r026Findings
                      (map finding-snapshot-copy after-findings))))))

(def +poo-guidance-corpus-scenarios+
  '(("poo-type-descriptor" . "t/scenarios/policy/poo-type-descriptor")
    ("poo-method-family-serialization" . "t/scenarios/policy/poo-method-family-serialization")
    ("poo-algebra-wrapper" . "t/scenarios/policy/poo-algebra-wrapper")
    ("poo-domain-algebra" . "t/scenarios/policy/poo-domain-algebra")
    ("poo-boundary-accessors" . "t/scenarios/policy/poo-boundary-accessors")))

(def +poo-guidance-target-rule-ids+
  ["GERBIL-SCHEME-AGENT-R006"
   "GERBIL-SCHEME-AGENT-R007"
   "GERBIL-SCHEME-AGENT-R008"
   "GERBIL-SCHEME-AGENT-R010"
   "GERBIL-SCHEME-AGENT-R017"
   "GERBIL-SCHEME-AGENT-R026"])

;; Snapshot
(def (poo-guidance-corpus-policy-snapshot)
  (list 'policyScenarioCorpus
        (list 'id "poo-guidance-corpus")
        (list 'mode "soft-guidance")
        (list 'contract
              "scenario corpus records POO parser facts and target findings without adding hard policy rules")
        (list 'scenarios
              (map (lambda (entry)
                     (poo-guidance-scenario-policy-snapshot
                      (car entry)
                      (cdr entry)))
                   +poo-guidance-corpus-scenarios+))))

;; : (-> ScenarioId ScenarioRoot Snapshot )
(def (poo-guidance-scenario-policy-snapshot id root)
  (let* ((scenario (make-policy-scenario id root))
         (result (policy-scenario-run scenario)))
    (list 'scenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (poo-guidance-phase-snapshot result 'before))
          (list 'after
                (poo-guidance-phase-snapshot result 'after)))))

;; : (-> PolicyScenarioResult ScenarioPhase Snapshot )
(def (poo-guidance-phase-snapshot result phase)
  (let (index (policy-scenario-index result phase))
    (list 'phase
          (list 'targetFindings
                (map finding-snapshot-copy
                     (poo-guidance-target-findings index)))
          (list 'pooForms
                (poo-guidance-poo-form-snapshots index)))))

;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-guidance-target-findings index)
  (filter (lambda (finding)
            (member (type-finding-rule-id finding)
                    +poo-guidance-target-rule-ids+))
          (run-agent-policy index)))

;; : (-> ProjectIndex (List Snapshot) )
(def (poo-guidance-poo-form-snapshots index)
  (apply append
         (map (lambda (file)
                (map poo-guidance-poo-form-snapshot
                     (source-file-poo-forms file)))
              (project-index-files index))))

;; : (-> PooFormFact Snapshot )
(def (poo-guidance-poo-form-snapshot fact)
  (list 'pooForm
        (list 'name (poo-form-fact-name fact))
        (list 'role (poo-form-fact-role fact))
        (list 'supers (poo-form-fact-supers fact))
        (list 'slots (poo-form-fact-slots fact))
        (list 'options (poo-form-fact-options fact))
        (list 'selector (poo-form-fact-selector fact))))

;; Snapshot
(def (functional-idiom-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "functional-idiom"
           "t/scenarios/policy/functional-idiom"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R009"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R009")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'guidance
                      (functional-idiom-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r009Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails PolicyGuidance )
(def (functional-idiom-guidance-snapshot details)
  (list (list 'kind (hash-get details 'kind))
        (list 'caller (hash-get details 'caller))
        (list 'advice (hash-get details 'advice))
        (list 'basicSyntaxSmells (hash-get details 'basicSyntaxSmells))
        (list 'nativeRepairContract
              (hash-get details 'nativeRepairContract))
        (list 'designFeaturePriority
              (hash-get details 'designFeaturePriority))
        (list 'sequenceIdioms (hash-get details 'sequenceIdioms))
        (list 'predicateIdioms (hash-get details 'predicateIdioms))
        (list 'compositionIdioms (hash-get details 'compositionIdioms))
        (list 'nativeLambdaIdioms (hash-get details 'nativeLambdaIdioms))
        (list 'typeclassIdioms (hash-get details 'typeclassIdioms))
        (list 'builderIdioms (hash-get details 'builderIdioms))
        (list 'styleGuide (hash-get details 'styleGuide))
        (list 'styleCommand (hash-get details 'styleCommand))
        (list 'detectedControlContexts
              (hash-get details 'detectedControlContexts))
        (list 'keepNamedLetWhen (hash-get details 'keepNamedLetWhen))
        (list 'learnedFrom (hash-get details 'learnedFrom))))

;; Snapshot
(def (controlled-branch-shape-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "controlled-branch-shape"
           "t/scenarios/policy/controlled-branch-shape"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R014"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R014")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'shape
                      (controlled-branch-shape-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r014Findings
                      (map finding-snapshot after-findings))))))

;; Snapshot
(def (controlled-branch-conditional-dispatch-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "controlled-branch-conditional-dispatch"
           "t/scenarios/policy/controlled-branch-conditional-dispatch"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R014"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R014")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'shape
                      (controlled-branch-shape-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r014Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails PolicyGuidance )
(def (controlled-branch-shape-guidance-snapshot details)
  (list (list 'caller (hash-get details 'caller))
        (list 'shape (hash-get details 'shape))
        (list 'matchCount (hash-get details 'matchCount))
        (list 'manualLoopCount (hash-get details 'manualLoopCount))
        (list 'conditionalBranchCount
              (hash-get details 'conditionalBranchCount))
        (list 'conditionalDispatchGate
              (hash-get details 'conditionalDispatchGate))
        (list 'evidence (hash-get details 'evidence))
        (list 'advice (hash-get details 'advice))
        (list 'styleGuide (hash-get details 'styleGuide))
        (list 'styleCommand (hash-get details 'styleCommand))
        (list 'rewriteScope (hash-get details 'rewriteScope))
        (list 'sourceBackedOwners
              (hash-get details 'sourceBackedOwners))
        (list 'sourceBackedRepairCandidates
              (hash-get details 'sourceBackedRepairCandidates))
        (list 'functionShape (hash-get details 'functionShape))
        (list 'expressionLevelRewrite
              (hash-get details 'expressionLevelRewrite))))

;; Snapshot
(def (typed-combinator-style-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "typed-combinator-style"
   "t/scenarios/policy/typed-combinator-style"))

;; Snapshot
(def (case-lambda-function-factory-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "case-lambda-function-factory"
   "t/scenarios/policy/case-lambda-function-factory"))

;; Snapshot
(def (generator-combinator-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "generator-combinator"
   "t/scenarios/policy/generator-combinator"))

;; Snapshot
(def (controlled-macro-syntax-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "controlled-macro-syntax"
   "t/scenarios/policy/controlled-macro-syntax"))

;; Snapshot
(def (typeclass-algebra-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "typeclass-algebra"
   "t/scenarios/policy/typeclass-algebra"))

;; : (-> ScenarioId ScenarioRoot Snapshot )
(def (typed-combinator-style-scenario-policy-snapshot id root)
  (let* ((scenario
          (make-policy-scenario
           id
           root))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R013"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding
                      (finding-snapshot-copy before-finding))
                (list 'style
                      (typed-combinator-style-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r013Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails PolicyGuidance )
(def (typed-combinator-style-guidance-snapshot details)
  (list (list 'styleGuide (hash-get details 'styleGuide))
        (list 'expectedCommentShape
              (hash-get details 'expectedCommentShape))
        (list 'compositionShape (hash-get details 'compositionShape))
        (list 'functionShape (hash-get details 'functionShape))
        (list 'agentRepairStandard
              (hash-get details 'agentRepairStandard))
        (list 'expressionLevelRewrite
              (hash-get details 'expressionLevelRewrite))
        (list 'definitionCount (hash-get details 'definitionCount))
        (list 'typedCommentCount (hash-get details 'typedCommentCount))
        (list 'missingTypedCommentCount
              (hash-get details 'missingTypedCommentCount))
        (list 'implementationEvidenceCount
              (hash-get details 'implementationEvidenceCount))
        (list 'qualityFacets (hash-get details 'qualityFacets))
        (list 'gerbilUtilsImplementationSignals
              (hash-get details 'gerbilUtilsImplementationSignals))
        (list 'generatorCombinatorSignals
              (hash-get details 'generatorCombinatorSignals))
        (list 'generatorContractTargets
              (hash-get details 'generatorContractTargets))
        (list 'controlledMacroSyntaxSignals
              (hash-get details 'controlledMacroSyntaxSignals))
        (list 'controlledMacroTargets
              (hash-get details 'controlledMacroTargets))
        (list 'typeclassAlgebraSignals
              (hash-get details 'typeclassAlgebraSignals))
        (list 'typeclassAlgebraTargets
              (hash-get details 'typeclassAlgebraTargets))
        (list 'gerbilContractProjectionSignals
              (hash-get details 'gerbilContractProjectionSignals))
        (list 'qualityFacetSteering
              (hash-get details 'qualityFacetSteering))))

;; : (-> TypeFinding SnapshotFinding )
(def (finding-snapshot-copy finding)
  [(type-finding-rule-id finding)
   (and (type-finding-path finding)
        (string-copy (type-finding-path finding)))
   (and (type-finding-selector finding)
        (string-copy (type-finding-selector finding)))
   (and (type-finding-message finding)
        (string-copy (type-finding-message finding)))])

;; Snapshot
(def (comment-quality-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "comment-quality"
           "t/scenarios/policy/comment-quality"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R015"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R015")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot-copy before-finding))
                (list 'comment
                      (comment-quality-guidance-snapshot before-details)))
          (list 'after
                (list 'r015Findings
                      (map finding-snapshot-copy after-findings))))))

;; : (-> PolicyDetails PolicyGuidance )
(def (comment-quality-guidance-snapshot details)
  (let* ((examples (hash-get details 'weakCommentExamples))
         (example (and (pair? examples) (car examples))))
    (list (list 'styleGuide (hash-get details 'styleGuide))
          (list 'evidenceSource (hash-get details 'evidenceSource))
          (list 'repairInstruction
                (hash-get details 'repairInstruction))
          (list 'repairOrder (hash-get details 'repairOrder))
          (list 'expectedCommentPrefix
                (hash-get details 'expectedCommentPrefix))
          (list 'commentLinePolicy
                (hash-get details 'commentLinePolicy))
          (list 'typedContractBoundary
                (hash-get details 'typedContractBoundary))
          (list 'weakCommentCount
                (hash-get details 'weakCommentCount))
          (list 'repairTargets
                (map string-copy
                     (hash-get details 'repairTargets)))
          (list 'exampleTarget
                (and (hash-get example 'target)
                     (string-copy (hash-get example 'target))))
          (list 'exampleContext (hash-get example 'context))
          (list 'exampleCommentKind (hash-get example 'commentKind))
          (list 'exampleQuality (hash-get example 'quality))
          (list 'exampleReasons (hash-get example 'reasons)))))

;; Snapshot
(def (harness-dependency-policy-application-policy-snapshot)
  (let* ((scenario
         (make-policy-scenario
           "harness-dependency-policy-application"
           "t/scenarios/policy/harness-dependency-policy-application"))
         (result (policy-scenario-run/checks scenario))
         (before-package
          (project-index-package (policy-scenario-index result 'before)))
         (after-package
          (project-index-package (policy-scenario-index result 'after)))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R013"))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'package
                      (package-agent-policy-snapshot before-package))
                (list 'finding
                      (finding-snapshot-copy before-finding)))
          (list 'after
                (list 'package
                      (package-agent-policy-snapshot after-package))
                (list 'r013Findings
                      (map finding-snapshot-copy after-findings))))))

;; Snapshot
(def (harness-dependency-policy-disable-requires-explanation-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "harness-dependency-policy-disable-requires-explanation"
           "t/scenarios/policy/harness-dependency-policy-disable-requires-explanation"))
         (result (policy-scenario-run/checks scenario))
         (before-package
          (project-index-package (policy-scenario-index result 'before)))
         (after-package
          (project-index-package (policy-scenario-index result 'after)))
         (before-policy-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R024"))
         (before-style-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R013"))
         (after-policy-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R024"))
         (after-style-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'package
                      (package-agent-policy-snapshot before-package))
                (list 'policyFinding
                      (finding-snapshot-copy before-policy-finding))
                (list 'styleFinding
                      (finding-snapshot-copy before-style-finding)))
          (list 'after
                (list 'package
                      (package-agent-policy-snapshot after-package))
                (list 'r024Findings
                      (map finding-snapshot-copy after-policy-findings))
                (list 'r013Findings
                      (map finding-snapshot-copy after-style-findings))))))

;; : (-> ProjectPackage PackagePolicySnapshot )
(def (package-agent-policy-snapshot package)
  (let (policy (and package (project-package-agent-policy package)))
    (list (list 'dependencies
                (and package (project-package-dependencies package)))
          (list 'default "all-rules-enabled")
          (list 'disabledRules
                (if policy (agent-policy-disabled-rules policy) '()))
          (list 'explanation
                (and policy (agent-policy-explanation policy))))))

;; Snapshot
(def (macro-controlled-helper-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "macro-controlled-helper"
           "t/scenarios/policy/macro-controlled-helper"))
         (result (policy-scenario-run scenario)))
    (let* ((after-findings
            (policy-scenario-findings
             result
             'after
             "GERBIL-SCHEME-AGENT-R011"))
           (before-finding
            (policy-scenario-required-finding
             result
             'before
             "GERBIL-SCHEME-AGENT-R011"))
           (before-details (type-finding-details before-finding))
           (after-macro
            (policy-scenario-required-first-macro-fact result 'after)))
      (list 'policyScenario
            (list 'id (policy-scenario-result-id result))
            (list 'before
                  (list 'finding (finding-snapshot before-finding))
                  (list 'guidance
                        (macro-controlled-helper-guidance-snapshot
                         before-details)))
            (list 'after
                  (list 'r011Findings
                        (map finding-snapshot after-findings))
                  (list 'macroFact
                        (macro-fact-snapshot after-macro)))))))

;; : (-> PolicyDetails PolicyGuidance )
(def (macro-controlled-helper-guidance-snapshot details)
  (let ((runtime (hash-get details 'runtimeSourceRequirement))
        (reference (hash-get details 'qualityReference)))
    (list (list 'macro (hash-get details 'macro))
          (list 'phase (hash-get details 'phase))
          (list 'hygienic (hash-get details 'hygienic))
          (list 'qualityFacets (hash-get details 'qualityFacets))
          (list 'allowedMacroShape (hash-get details 'allowedMacroShape))
          (list 'runtimeSelectorFormat
                (hash-get runtime 'selectorFormat))
          (list 'styleReferencePattern
                (hash-get reference 'referencePattern))
          (list 'styleReferenceExamples
                (hash-get reference 'referenceExamples))
          (list 'escapeConstraint
                (hash-get details 'agentEscapeConstraint)))))

;; Snapshot
(def (predicate-family-combinator-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "predicate-family-combinator"
           "t/scenarios/policy/predicate-family-combinator"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R016"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R016")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'profile
                      (predicate-combinator-profile-snapshot
                       before-details)))
          (list 'after
                (list 'r016Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails ProfileSnapshot )
(def (predicate-combinator-profile-snapshot details)
  (let ((reference (hash-get details 'qualityReference)))
    (list (list 'styleGuide (hash-get details 'styleGuide))
          (list 'subject (hash-get details 'subject))
          (list 'predicateCount (hash-get details 'predicateCount))
          (list 'fieldKeys (hash-get details 'fieldKeys))
          (list 'repeatedCallees (hash-get details 'repeatedCallees))
          (list 'referencePattern
                (hash-get reference 'referencePattern))
          (list 'referenceExamples
                (hash-get reference 'referenceExamples))
          (list 'qualitySignals (hash-get reference 'qualitySignals))
          (list 'repairStandard
                (hash-get details 'agentRepairStandard)))))

;; Snapshot
(def (build-support-shell-template-policy-snapshot)
  (build-runtime-quality-policy-snapshot
   "build-support-shell-template"
   "t/scenarios/policy/build-support-shell-template"))

;; Snapshot
(def (package-build-shell-pipeline-policy-snapshot)
  (build-runtime-quality-policy-snapshot
   "package-build-shell-pipeline"
   "t/scenarios/policy/package-build-shell-pipeline"))

;; Snapshot
(def (package-build-canonical-shape-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "package-build-canonical-shape"
           "t/scenarios/policy/package-build-canonical-shape"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R025"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R025")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'buildShape
                      (package-build-canonical-shape-snapshot
                       before-details)))
          (list 'after
                (list 'r025Findings
                      (map finding-snapshot after-findings))))))

;; Snapshot
(def (package-build-std-build-script-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "package-build-std-build-script"
           "t/scenarios/policy/package-build-std-build-script"))
         (result (policy-scenario-run scenario))
         (before-findings
          (policy-scenario-findings
           result
           'before
           "GERBIL-SCHEME-AGENT-R025"))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R025")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'r025Findings
                      (map finding-snapshot before-findings)))
          (list 'after
                (list 'r025Findings
                      (map finding-snapshot after-findings))))))

;; Snapshot
(def (package-build-std-make-ssi-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "package-build-std-make-ssi"
           "t/scenarios/policy/package-build-std-make-ssi"))
         (result (policy-scenario-run scenario))
         (before-findings
          (policy-scenario-findings
           result
           'before
           "GERBIL-SCHEME-AGENT-R025"))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R025")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'r025Findings
                      (map finding-snapshot before-findings)))
          (list 'after
                (list 'r025Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails BuildShapeSnapshot )
(def (package-build-canonical-shape-snapshot details)
  (list (list 'kind (hash-get details 'kind))
        (list 'nativeBuildImport
              (hash-get details 'nativeBuildImport))
        (list 'nativeBuildImportModifier
              (hash-get details 'nativeBuildImportModifier))
        (list 'buildSpecEntrypoint
              (hash-get details 'buildSpecEntrypoint))
        (list 'manualCompilerDispatch
              (hash-get details 'manualCompilerDispatch))
        (list 'handWrittenMain
              (hash-get details 'handWrittenMain))
        (list 'allowedShape (hash-get details 'allowedShape))
        (list 'disallowedShape (hash-get details 'disallowedShape))
        (list 'sourceEvidence (hash-get details 'sourceEvidence))
        (list 'nativeFactSource (hash-get details 'nativeFactSource))
        (list 'next (hash-get details 'next))))

;; : (-> ScenarioId ScenarioRoot Snapshot )
(def (build-runtime-quality-policy-snapshot id root)
  (let* ((scenario
          (make-policy-scenario
           id
           root))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R020"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R020")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'runtimeQuality
                      (build-runtime-quality-snapshot before-details)))
          (list 'after
                (list 'r020Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails RuntimeQualitySnapshot )
(def (build-runtime-quality-snapshot details)
  (list (list 'kind (hash-get details 'kind))
        (list 'detectionCombiner (hash-get details 'detectionCombiner))
        (list 'detectionCombinerKind
              (hash-get details 'detectionCombinerKind))
        (list 'detectionSourcePattern
              (hash-get details 'detectionSourcePattern))
        (list 'requiredGroups (hash-get details 'requiredGroups))
        (list 'evidenceGroups (hash-get details 'evidenceGroups))
        (list 'evidenceCounts (hash-get details 'evidenceCounts))
        (list 'allowedShape (hash-get details 'allowedShape))
        (list 'disallowedShape (hash-get details 'disallowedShape))
        (list 'next (hash-get details 'next))))

;; Snapshot
(def (dependency-manual-object-adapter-policy-snapshot)
  (dependency-adapter-policy-snapshot
   "dependency-manual-object-adapter"
   "t/scenarios/policy/dependency-manual-object-adapter"))

;; Snapshot
(def (dependency-protocol-adapter-policy-snapshot)
  (dependency-adapter-policy-snapshot
   "dependency-protocol-adapter"
   "t/scenarios/policy/dependency-protocol-adapter"))

;; : (-> ScenarioId ScenarioRoot Snapshot )
(def (dependency-adapter-policy-snapshot id root)
  (let* ((scenario
          (make-policy-scenario
           id
           root))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-R017"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-R017")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'adapter
                      (dependency-adapter-profile-snapshot before-details)))
          (list 'after
                (list 'r017Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails AdapterProfileSnapshot )
(def (dependency-adapter-profile-snapshot details)
  (list (list 'styleGuide (hash-get details 'styleGuide))
        (list 'dependency (hash-get details 'dependency))
        (list 'quality (hash-get details 'quality))
        (list 'manualObjectEncodingRisk
              (hash-get details 'manualObjectEncodingRisk))
        (list 'genericContractWitnessKind
              (hash-get details 'genericContractWitnessKind))
        (list 'contractWitnessPresent
              (hash-get details 'contractWitnessPresent))
        (list 'contractWitnessKind
              (hash-get details 'contractWitnessKind))
        (list 'missingEvidence (hash-get details 'missingEvidence))
        (list 'qualityFacets (hash-get details 'qualityFacets))
        (list 'derivedCapabilities
              (hash-get details 'derivedCapabilities))
        (list 'methodTablePrimitiveSlots
              (hash-get details 'methodTablePrimitiveSlots))
        (list 'methodTableDerivedFamilies
              (hash-get details 'methodTableDerivedFamilies))
        (list 'adapterRepairShape
              (hash-get details 'adapterRepairShape))
        (list 'agentRepairStandard
              (hash-get details 'agentRepairStandard))))

;; : (-> MacroFact MacroFactSnapshot )
(def (macro-fact-snapshot fact)
  (list (list 'macro (macro-fact-name fact))
        (list 'transformer (macro-fact-transformer fact))
        (list 'phase (macro-fact-phase fact))
        (list 'hygienic (macro-fact-hygienic fact))
        (list 'qualityFacets (macro-fact-quality-facets fact))))

;; Snapshot
(def (check-policy-snapshot-fixtures)
  (check (downstream-poo-agent-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-downstream-poo-agent.ss"))
  (check (functional-idiom-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-functional-idiom.ss"))
  (check (controlled-branch-shape-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-controlled-branch-shape.ss"))
  (check (controlled-branch-conditional-dispatch-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-controlled-branch-conditional-dispatch.ss"))
  (check (typed-combinator-style-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-typed-combinator-style.ss"))
  (check (case-lambda-function-factory-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-case-lambda-function-factory.ss"))
  (check (generator-combinator-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-generator-combinator.ss"))
  (check (controlled-macro-syntax-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-controlled-macro-syntax.ss"))
  (check (typeclass-algebra-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-typeclass-algebra.ss"))
  (check (comment-quality-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-comment-quality.ss"))
  (check (harness-dependency-policy-application-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-harness-dependency-policy-application.ss"))
  (check (harness-dependency-policy-disable-requires-explanation-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-harness-dependency-policy-disable-requires-explanation.ss"))
  (check (macro-controlled-helper-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-macro-controlled-helper.ss"))
  (check (predicate-family-combinator-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-predicate-family-combinator.ss"))
  (check (build-support-shell-template-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-build-support-shell-template.ss"))
  (check (package-build-shell-pipeline-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-shell-pipeline.ss"))
  (check (package-build-canonical-shape-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-canonical-shape.ss"))
  (check (package-build-std-build-script-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-std-build-script.ss"))
  (check (package-build-std-make-ssi-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-std-make-ssi.ss"))
  (check (poo-prototype-fixed-point-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-poo-prototype-fixed-point.ss"))
  (check (poo-guidance-corpus-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-poo-guidance-corpus.ss"))
  (check (dependency-manual-object-adapter-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-dependency-manual-object-adapter.ss"))
  (check (dependency-protocol-adapter-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-dependency-protocol-adapter.ss")))

;;; -*- Gerbil -*-
;;; Stable snapshot projections for provider facts and command packets.

(import :checker/facade
        :constants
        :extensions/facade
        :parser/facade
        :snapshot/support
        :support/time
        :std/srfi/13
        :types/facade)

(export snapshot-load
        project-package-snapshot
        extension-fact-snapshot
        extension-search-snapshot
        pattern-evidence-snapshot
        pattern-search-snapshot
        runtime-source-fact-snapshot
        runtime-source-search-snapshot
        language-evidence-fact-snapshot
        language-evidence-search-snapshot
        guide-snapshot
        registry-snapshot
        compare-fact-snapshot
        compare-search-snapshot
        parser-source-file-snapshot
        self-apply-findings-snapshot
        finding-snapshot
        bench-report-snapshot
        check-report-snapshot)

(def (snapshot-load path)
  (call-with-input-file path read))

(def (project-package-snapshot package)
  (list 'projectPackage
        (list 'path (project-package-path package))
        (list 'name (project-package-name package))
        (list 'dependencies (snapshot-list (project-package-dependencies package)))
        (list 'fields
              (list 'packageManager (project-package-manager package)))))

(def (extension-fact-snapshot fact)
  (list 'providerExtension
        (list 'name (extension-fact-name fact))
        (list 'activation (extension-fact-activation fact))
        (list 'dependencyMode (extension-fact-dependency-mode fact))
        (list 'packageManager (extension-fact-package-manager fact))
        (list 'package (extension-fact-package fact))
        (list 'dependencies (snapshot-list (extension-fact-dependencies fact)))
        (list 'capabilities (snapshot-list (extension-fact-capabilities fact)))))

(def (extension-search-snapshot query matches next)
  (list 'extensionSearch
        (list 'namespace "extension")
        (list 'authority "ecosystem-extension")
        (list 'evidenceGrade (if (null? matches) "unknown" "fact"))
        (list 'query query)
        (list 'matches (map extension-fact-snapshot matches))
        (list 'next next)))

(def (pattern-evidence-snapshot pattern)
  (list 'pattern
        (list 'id (hash-get pattern 'id))
        (list 'extension (hash-get pattern 'extension))
        (list 'focus (hash-get pattern 'focus))
        (source-ref-snapshot (hash-get pattern 'sourceRef))
        (list 'sourceOwners (snapshot-list (hash-get pattern 'sourceOwners)))
        (list 'agentScenario (hash-get pattern 'agentScenario))
        (list 'intent (hash-get pattern 'intent))
        (list 'selectors
              (map pattern-selector-snapshot
                   (hash-get pattern 'selectors)))
        (list 'minimalForms
              (map pattern-form-snapshot
                   (hash-get pattern 'minimalForms)))
        (list 'failureCases
              (map pattern-failure-case-snapshot
                   (hash-get pattern 'failureCases)))
        (list 'qualitySignals
              (snapshot-list (hash-get pattern 'qualitySignals)))
        (list 'witness (hash-get pattern 'witness))))

(def (source-ref-snapshot source-ref)
  (list 'sourceRef
        (list 'kind (hash-get source-ref 'kind))
        (list 'manager (hash-get source-ref 'manager))
        (list 'package (hash-get source-ref 'package))
        (list 'dependency (hash-get source-ref 'dependency))
        (list 'repository (hash-get source-ref 'repository))
        (list 'pathPolicy (hash-get source-ref 'pathPolicy))
        (list 'selectorScheme (hash-get source-ref 'selectorScheme))))

(def (pattern-selector-snapshot selector)
  (list 'selector
        (list 'role (hash-get selector 'role))
        (list 'symbol (hash-get selector 'symbol))
        (list 'selector (hash-get selector 'selector))))

(def (pattern-form-snapshot form)
  (list 'form
        (list 'role (hash-get form 'role))
        (list 'symbol (hash-get form 'symbol))
        (pattern-form-template-snapshot (hash-get form 'template))
        (list 'selector (hash-get form 'selector))))

(def (pattern-form-template-snapshot template)
  (list 'template
        (list 'head (hash-get template 'head))
        (list 'operands (snapshot-list (hash-get template 'operands)))
        (list 'keywords (snapshot-list (hash-get template 'keywords)))))

(def (pattern-failure-case-snapshot failure)
  (list 'failureCase
        (list 'id (hash-get failure 'id))
        (if (hash-key? failure 'riskKind)
          (list 'riskKind (hash-get failure 'riskKind))
          (list 'risk (hash-get failure 'risk)))
        (if (hash-key? failure 'correctiveAction)
          (list 'correctiveAction (hash-get failure 'correctiveAction))
          (list 'correction (hash-get failure 'correction)))
        (if (hash-key? failure 'badPattern)
          (list 'badPattern (hash-get failure 'badPattern))
          (list 'badPattern ""))
        (if (hash-key? failure 'selectors)
          (list 'selectors (snapshot-list (hash-get failure 'selectors)))
          (list 'selectors '()))))

(def (pattern-search-snapshot query pattern missing next)
  (let (missing-items (snapshot-list missing))
    (list 'patternSearch
          (list 'namespace "pattern")
          (list 'authority "executable-pattern")
          (list 'evidenceGrade (if pattern "fact" "unknown"))
          (list 'quality (cond
                          ((not pattern) "insufficient")
                          ((null? missing) "verified")
                          (else "partial")))
          (list 'query query)
          (list 'pattern (and pattern (pattern-evidence-snapshot pattern)))
          (list 'missing missing-items)
          (list 'witness (if pattern (hash-get pattern 'witness) "pending"))
          (list 'next next))))

(def (runtime-source-fact-snapshot fact)
  (let* ((details (hash-get fact 'details))
         (source-ref (hash-get details 'sourceRef))
         (acquisition (hash-get details 'acquisition)))
    (list 'runtimeSourceFact
          (list 'id (hash-get fact 'id))
          (list 'summary (hash-get fact 'summary))
          (list 'evidenceGrade (hash-get fact 'evidenceGrade))
          (list 'witness (hash-get fact 'witness))
          (runtime-source-ref-snapshot source-ref)
          (runtime-source-acquisition-snapshot acquisition)
          (optional-snapshot 'selectorResolver details selector-resolver-snapshot)
          (list 'sourceExamples
                (map source-example-snapshot
                     (snapshot-detail-list-value details 'sourceExamples)))
          (list 'sourceComments
                (map source-comment-snapshot
                     (snapshot-detail-list-value details 'sourceComments)))
          (list 'selectors
                (map evidence-selector-snapshot
                     (hash-get fact 'selectors)))
          (list 'agentScenario (hash-get fact 'agentScenario))
          (list 'intent (hash-get fact 'intent))
          (list 'failureCases
                (map evidence-failure-case-snapshot
                     (hash-get fact 'failureCases)))
          (list 'qualitySignals
                (snapshot-list (hash-get fact 'qualitySignals))))))

(def (runtime-source-ref-snapshot source-ref)
  (list 'sourceRef
        (list 'kind (hash-get source-ref 'kind))
        (list 'manager (hash-get source-ref 'manager))
        (list 'repository (hash-get source-ref 'repository))
        (list 'checkoutPolicy (hash-get source-ref 'checkoutPolicy))
        (list 'statePathPolicy (hash-get source-ref 'statePathPolicy))
        (list 'selectorScheme (hash-get source-ref 'selectorScheme))))

(def (runtime-source-acquisition-snapshot acquisition)
  (list 'acquisition
        (list 'owner (hash-get acquisition 'owner))
        (list 'operation (hash-get acquisition 'operation))
        (list 'stateNamespace (hash-get acquisition 'stateNamespace))
        (list 'indexOwner (hash-get acquisition 'indexOwner))))

(def (evidence-selector-snapshot selector)
  (list 'selector
        (list 'role (hash-get selector 'role))
        (list 'symbol (hash-get selector 'symbol))
        (list 'selector (hash-get selector 'selector))))

(def (evidence-failure-case-snapshot failure)
  (list 'failureCase
        (list 'id (hash-get failure 'id))
        (list 'risk (failure-risk-snapshot failure))
        (list 'correction (failure-correction-snapshot failure))))

(def (failure-risk-snapshot failure)
  (cond
   ((hash-key? failure 'risk) (hash-get failure 'risk))
   ((hash-key? failure 'riskKind) (hash-get failure 'riskKind))
   (else "unknown")))

(def (failure-correction-snapshot failure)
  (cond
   ((hash-key? failure 'correction) (hash-get failure 'correction))
   ((hash-key? failure 'correctiveAction) (hash-get failure 'correctiveAction))
   (else "unknown")))

(def (runtime-source-search-snapshot query facts next)
  (list 'runtimeSourceSearch
        (list 'namespace "runtime-source")
        (list 'authority "runtime-version-source")
        (list 'evidenceGrade (if (null? facts) "unknown" "fact"))
        (list 'quality (if (null? facts)
                         "insufficient"
                         "version-matched-source-plan"))
        (list 'query query)
        (list 'facts (map runtime-source-fact-snapshot facts))
        (list 'missing (if (null? facts)
                         (list "runtime-source-fact")
                         '()))
        (list 'witness (if (null? facts)
                         "pending"
                         (hash-get (car facts) 'witness)))
        (list 'next next)))

(def (language-evidence-fact-snapshot fact)
  (list 'languageEvidenceFact
        (list 'id (hash-get fact 'id))
        (list 'summary (hash-get fact 'summary))
        (list 'evidenceGrade (hash-get fact 'evidenceGrade))
        (list 'witness (hash-get fact 'witness))
        (list 'next (hash-get fact 'next))
        (language-evidence-details-snapshot (hash-get fact 'details))
        (list 'selectors
              (map evidence-selector-snapshot
                   (hash-get fact 'selectors)))
        (list 'agentScenario (hash-get fact 'agentScenario))
        (list 'intent (hash-get fact 'intent))
        (list 'failureCases
              (map evidence-failure-case-snapshot
                   (hash-get fact 'failureCases)))
        (list 'qualitySignals
              (snapshot-list (hash-get fact 'qualitySignals)))))

(def (language-evidence-details-snapshot details)
  (cons 'details
        (append
         (if (hash-key? details 'gerbilHome)
           [(list 'runtimeResolved #t)
            (list 'gxiExists (hash-get details 'gxiExists))
            (list 'gscExists (hash-get details 'gscExists))
            (list 'loadPathKnown (pair? (hash-get details 'loadPath)))]
           '())
         (snapshot-detail-string details 'rule)
         (snapshot-detail-string details 'authority)
         (snapshot-detail-string details 'module)
         (snapshot-detail-list details 'capabilities)
         (snapshot-detail-string details 'minimalImport)
         (snapshot-detail-string details 'runtimeSourceSelector)
         (snapshot-detail-object details 'selectorResolver selector-resolver-snapshot)
         (snapshot-detail-objects details 'sourceExamples source-example-snapshot)
         (snapshot-detail-objects details 'sourceComments source-comment-snapshot)
         (snapshot-detail-string details 'reference)
         (snapshot-detail-string details 'testDirectory)
         (snapshot-detail-list details 'policyRules)
         (snapshot-detail-string details 'styleDoc))))

(def (snapshot-detail-string details key)
  (if (hash-key? details key)
    [(list key (hash-get details key))]
    '()))

(def (snapshot-detail-list details key)
  (if (hash-key? details key)
    [(list key (snapshot-list (hash-get details key)))]
    '()))

(def (snapshot-detail-list-value details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))

(def (snapshot-detail-object details key snapshot-proc)
  (if (hash-key? details key)
    [(snapshot-proc (hash-get details key))]
    '()))

(def (snapshot-detail-objects details key snapshot-proc)
  (if (hash-key? details key)
    [(list key (map snapshot-proc (hash-get details key)))]
    '()))

(def (optional-snapshot label details snapshot-proc)
  (if (hash-key? details label)
    (snapshot-proc (hash-get details label))
    (list label #f)))

(def (selector-resolver-snapshot resolver)
  (list 'selectorResolver
        (list 'scheme (hash-get resolver 'scheme))
        (list 'owner (hash-get resolver 'owner))
        (list 'stateNamespace (hash-get resolver 'stateNamespace))
        (list 'selectorFormat (hash-get resolver 'selectorFormat))
        (list 'output (hash-get resolver 'output))
        (list 'indexOwner (hash-get resolver 'indexOwner))))

(def (source-example-snapshot example)
  (list 'sourceExample
        (list 'id (hash-get example 'id))
        (list 'role (hash-get example 'role))
        (list 'symbol (hash-get example 'symbol))
        (list 'selector (hash-get example 'selector))
        (source-example-form-snapshot (hash-get example 'form))
        (list 'commentMode (hash-get example 'commentMode))))

(def (source-example-form-snapshot form)
  (list 'form
        (list 'head (hash-get form 'head))
        (list 'operands (snapshot-list (hash-get form 'operands)))
        (list 'keywords (snapshot-list (hash-get form 'keywords)))))

(def (source-comment-snapshot comment)
  (list 'sourceComment
        (list 'id (hash-get comment 'id))
        (list 'selector (hash-get comment 'selector))
        (list 'extractor (hash-get comment 'extractor))
        (list 'summary (hash-get comment 'summary))
        (list 'fallback (hash-get comment 'fallback))))

(def (language-evidence-search-snapshot namespace authority query facts next)
  (list 'languageEvidenceSearch
        (list 'namespace namespace)
        (list 'authority authority)
        (list 'evidenceGrade (if (null? facts) "unknown" "fact"))
        (list 'query query)
        (list 'facts (map language-evidence-fact-snapshot facts))
        (list 'next next)))

(def (guide-snapshot lines)
  (list 'guide
        (list 'lines (snapshot-list lines))))

(def (registry-snapshot registry)
  (let* ((language (car (hash-get registry 'languages)))
         (schemas (hash-get language 'schemas))
         (descriptors (hash-get language 'methodDescriptors)))
    (list 'registry
          (list 'registryId (hash-get registry 'registryId))
          (list 'registryVersion (hash-get registry 'registryVersion))
          (list 'languageId (hash-get language 'languageId))
          (list 'providerId (hash-get language 'providerId))
          (list 'methods (snapshot-list (hash-get language 'methods)))
          (list 'schemas (map schema-registry-entry-snapshot schemas))
          (list 'methodDescriptors
                (map method-descriptor-snapshot descriptors)))))

(def (schema-registry-entry-snapshot schema)
  (list 'schema
        (list 'schemaId (hash-get schema 'schemaId))
        (list 'schemaVersion (hash-get schema 'schemaVersion))
        (list 'path (hash-get schema 'path))))

(def (method-descriptor-snapshot descriptor)
  (list 'methodDescriptor
        (list 'method (hash-get descriptor 'method))
        (list 'command (hash-get descriptor 'command))
        (list 'outputSchemaIds
              (snapshot-list (hash-get descriptor 'outputSchemaIds)))))

(def (compare-fact-snapshot fact)
  (list 'comparison
        (list 'id (hash-get fact 'id))
        (list 'summary (hash-get fact 'summary))
        (list 'evidenceGrade (hash-get fact 'evidenceGrade))
        (list 'witness (hash-get fact 'witness))
        (list 'next (hash-get fact 'next))
        (compare-side-snapshot 'left (hash-get fact 'left))
        (compare-side-snapshot 'right (hash-get fact 'right))
        (list 'result (hash-get fact 'result))
        (list 'agentScenario (hash-get fact 'agentScenario))
        (list 'intent (hash-get fact 'intent))
        (list 'failureCases
              (map evidence-failure-case-snapshot
                   (hash-get fact 'failureCases)))
        (list 'qualitySignals
              (snapshot-list (hash-get fact 'qualitySignals)))))

(def (compare-side-snapshot label side)
  (cons label
        (append
         [(list 'kind (hash-get side 'kind))]
         (if (hash-key? side 'gxiResolved)
           [(list 'gxiResolved (hash-get side 'gxiResolved))]
           '())
         (if (hash-key? side 'gscResolved)
           [(list 'gscResolved (hash-get side 'gscResolved))]
           '())
         (snapshot-detail-string side 'source)
         (snapshot-detail-string side 'status)
         (snapshot-detail-list side 'targetVersions)
         (snapshot-detail-string side 'compileMode)
         (snapshot-detail-string side 'stateNamespace))))

(def (compare-search-snapshot query facts next)
  (list 'compareSearch
        (list 'namespace "compare")
        (list 'authority "active-runtime-vs-documented")
        (list 'evidenceGrade (if (null? facts) "unknown" "fact"))
        (list 'quality (if (null? facts) "insufficient" "verified"))
        (list 'query query)
        (list 'comparisons (map compare-fact-snapshot facts))
        (list 'missing (if (null? facts)
                         (list "compare-fact")
                         '()))
        (list 'witness (if (null? facts)
                         "pending"
                         (hash-get (car facts) 'witness)))
        (list 'next next)))

(def (parser-source-file-snapshot file)
  (list 'parserSourceFile
        (list 'path (source-file-path file))
        (list 'definitions
              (map parser-definition-snapshot
                   (source-file-definitions file)))
        (list 'moduleImports
              (map parser-module-import-snapshot
                   (source-file-module-imports file)))
        (list 'macros
              (map parser-macro-snapshot
                   (source-file-macros file)))
        (list 'bindings
              (map parser-binding-snapshot
                   (source-file-bindings file)))
        (list 'pooForms
              (map parser-poo-form-snapshot
                   (source-file-poo-forms file)))
        (list 'higherOrderForms
              (map parser-higher-order-form-snapshot
                   (source-file-higher-order-forms file)))
        (list 'calls
              (map parser-call-snapshot
                   (source-file-calls file)))))

(def (parser-definition-snapshot defn)
  (list 'definition
        (list 'name (definition-name defn))
        (list 'kind (definition-kind defn))
        (list 'formals (snapshot-list (definition-formals defn)))
        (list 'selector (definition-selector defn))))

(def (parser-module-import-snapshot fact)
  (list 'moduleImport
        (list 'module (module-import-fact-module fact))
        (list 'phase (module-import-fact-phase fact))
        (list 'modifier (module-import-fact-modifier fact))
        (list 'symbols (snapshot-list (module-import-fact-symbols fact)))
        (list 'selector (module-import-fact-selector fact))))

(def (parser-macro-snapshot fact)
  (list 'macro
        (list 'name (macro-fact-name fact))
        (list 'kind (macro-fact-kind fact))
        (list 'transformer (macro-fact-transformer fact))
        (list 'phase (macro-fact-phase fact))
        (list 'patternCount (macro-fact-pattern-count fact))
        (list 'hygienicSyntax (macro-fact-hygienic fact))
        (list 'selector (macro-fact-selector fact))))

(def (parser-binding-snapshot fact)
  (list 'binding
        (list 'name (binding-fact-name fact))
        (list 'kind (binding-fact-kind fact))
        (list 'scope (binding-fact-scope fact))
        (list 'valueType (or (binding-fact-value-type fact) "unknown"))
        (list 'selector (binding-fact-selector fact))))

(def (parser-poo-form-snapshot fact)
  (list 'pooForm
        (list 'name (poo-form-fact-name fact))
        (list 'kind (poo-form-fact-kind fact))
        (list 'role (poo-form-fact-role fact))
        (list 'generic (or (poo-form-fact-generic fact) ""))
        (list 'receiver (or (poo-form-fact-receiver fact) ""))
        (list 'receiverType (or (poo-form-fact-receiver-type fact) ""))
        (list 'supers (snapshot-list (poo-form-fact-supers fact)))
        (list 'slots (snapshot-list (poo-form-fact-slots fact)))
        (list 'options (snapshot-list (poo-form-fact-options fact)))
        (list 'specializers (snapshot-list (poo-form-fact-specializers fact)))
        (list 'specializerTypes (snapshot-list (poo-form-fact-specializer-types fact)))
        (list 'selector (poo-form-fact-selector fact))))

(def (parser-higher-order-form-snapshot fact)
  (list 'higherOrderForm
        (list 'name (higher-order-fact-name fact))
        (list 'kind (higher-order-fact-kind fact))
        (list 'role (higher-order-fact-role fact))
        (list 'operandCount (higher-order-fact-operand-count fact))
        (list 'arities (snapshot-list (higher-order-fact-arities fact)))
        (list 'formals (snapshot-list (higher-order-fact-formals fact)))
        (list 'caller (or (higher-order-fact-caller fact) ""))
        (list 'selector (higher-order-fact-selector fact))))

(def (parser-call-snapshot fact)
  (list 'call
        (list 'callee (call-fact-callee fact))
        (list 'arity (call-fact-arity fact))
        (list 'caller (or (call-fact-caller fact) ""))
        (list 'arguments (snapshot-list (call-fact-arguments fact)))
        (list 'argumentTypes
              (snapshot-list
               (map (lambda (type) (or type "unknown"))
                    (call-fact-argument-types fact))))
        (list 'selector (call-fact-selector fact))))

(def (finding-snapshot finding)
  [(type-finding-rule-id finding)
   (type-finding-path finding)
   (type-finding-selector finding)
   (type-finding-message finding)])

(def (self-apply-findings-snapshot findings)
  (list 'selfApplyFindings
        (list 'languageId +language-id+)
        (list 'providerId +provider-id+)
        (list 'status (type-status findings))
        (list 'findingCount (length findings))
        (list 'findings (map finding-snapshot findings))))

(def (check-report-snapshot index findings)
  (list 'checkReport
        (list 'languageId +language-id+)
        (list 'providerId +provider-id+)
        (list 'status (type-status findings))
        (list 'findings (map finding-snapshot findings))))

(def (bench-packet-has-key? packet key)
  (or (hash-key? packet key)
      (hash-key? packet (symbol->string key))))

(def (bench-packet-get packet key)
  (if (hash-key? packet key)
    (hash-get packet key)
    (hash-get packet (symbol->string key))))

(def (bench-step-snapshot benchmark)
  (list 'bench
        (list 'name (bench-packet-get benchmark 'name))
        (list 'iterations (bench-packet-get benchmark 'iterations))
        (list 'durationMs (duration-state
                            (bench-packet-get benchmark 'durationMs)))
        (list 'averageMicros (duration-state
                               (bench-packet-get benchmark 'averageMicros)))
        (list 'averageMs (duration-state
                           (bench-packet-get benchmark 'averageMs)))))

(def (bench-performance-finding-snapshot finding)
  (list 'finding
        (list 'kind (bench-packet-get finding 'kind))
        (list 'severity (bench-packet-get finding 'severity))
        (list 'summary (bench-packet-get finding 'summary))
        (list 'totalMs (duration-state
                         (bench-packet-get finding 'totalMs)))
        (list 'maxTotalMs (bench-packet-get finding 'maxTotalMs))
        (list 'exceededByMs (duration-state
                              (bench-packet-get finding 'exceededByMs)))
        (list 'slowestBenchmarkName
              (bench-packet-get finding 'slowestBenchmarkName))
        (list 'slowestBenchmarkDurationMs
              (duration-state
               (bench-packet-get finding 'slowestBenchmarkDurationMs)))))

(def (bench-report-snapshot packet)
  (list 'benchReport
        (list 'languageId +language-id+)
        (list 'providerId +provider-id+)
        (list 'schemaId (bench-packet-get packet 'schemaId))
        (list 'status (bench-packet-get packet 'status))
        (list 'iterations (bench-packet-get packet 'iterations))
        (list 'maxTotalMs (if (bench-packet-has-key? packet 'maxTotalMs)
                            (bench-packet-get packet 'maxTotalMs)
                            #f))
        (list 'totalMs (duration-state
                         (bench-packet-get packet 'totalMs)))
        (list 'files (bench-packet-get packet 'files))
        (list 'definitions (bench-packet-get packet 'definitions))
        (list 'findings (bench-packet-get packet 'findings))
        (list 'performanceFindings
              (map bench-performance-finding-snapshot
                   (bench-packet-get packet 'performanceFindings)))
        (list 'slowestBenchmark
              (bench-step-snapshot
               (bench-packet-get packet 'slowestBenchmark)))
        (list 'benchmarks
              (map bench-step-snapshot
                   (bench-packet-get packet 'benchmarks)))))

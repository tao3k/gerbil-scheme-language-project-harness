;;; -*- Gerbil -*-
;;; Stable snapshot projections for provider facts and command packets.

(import :checker/facade
        :constants
        :extensions/facade
        :parser/facade
        :parser/query
        :support/list
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
        extension-packet-snapshot
        search-prime-snapshot
        self-apply-findings-snapshot
        finding-snapshot
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
         (snapshot-detail-string side 'status))))

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

(def (extension-packet-snapshot index)
  (list 'extensionPacket
        (project-package-snapshot (project-index-package index))
        (list 'extensions
              (map extension-fact-snapshot (project-extension-facts index)))
        (list 'searchLines (project-extension-search-lines index))))

(def (search-prime-snapshot index)
  (let* ((owners (take* (ranked-files index) 100))
         (package (project-index-package index))
         (extensions (project-extension-facts index)))
    (list 'searchPrime
          (list 'schemaId "agent.semantic-protocols.semantic-search-packet")
          (list 'schemaVersion "1")
          (list 'protocolId "agent.semantic-protocols.semantic-language")
          (list 'protocolVersion "1")
          (list 'languageId +language-id+)
          (list 'providerId +provider-id+)
          (list 'binary +provider-id+)
          (list 'namespace "agent.semantic-protocols.gerbil-scheme")
          (list 'method "search/prime")
          (list 'projectRoot (snapshot-project-root index))
          (list 'view "prime")
          (list 'renderMode "facts")
          (search-header-snapshot index)
          (project-package-snapshot package)
          (list 'extensions (map extension-fact-snapshot extensions))
          (list 'nodes (search-prime-node-snapshots package extensions owners))
          (list 'edges (search-prime-edge-snapshots package extensions owners))
          (list 'owners (map owner-snapshot owners))
          (list 'hits (map-indexed owner-hit-snapshot owners))
          (list 'findings '())
          (list 'nextActions
                (list (list 'nextAction
                            (list 'kind "search")
                            (list 'target "fzf")
                            (list 'scope (snapshot-project-root index))
                            (list 'fields
                                  (list 'command
                                        "gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")))))
          (list 'notes
                (list (list 'note
                            (list 'kind "parser")
                            (list 'message "core-read-module native Scheme reader facts")))))))

(def (search-header-snapshot index)
  (list 'header
        (list 'kind "search-prime")
        (list 'fields
              (list 'parser "core-read-module")
              (list 'files (length (project-index-files index)))
              (list 'definitions (length (project-definitions index))))))

(def (search-prime-node-snapshots package extensions owners)
  (append (if package (list (package-node-snapshot package)) '())
          (map extension-node-snapshot extensions)
          (map-indexed owner-node-snapshot owners)))

(def (search-prime-edge-snapshots package extensions owners)
  (if package
    (append (map (lambda (extension)
                   (list 'edge
                         (list 'from (package-node-id package))
                         (list 'kind "activates")
                         (list 'to (extension-node-id extension))))
                 extensions)
            (map (lambda (owner)
                   (list 'edge
                         (list 'from (package-node-id package))
                         (list 'kind "owns")
                         (list 'to (owner-node-id owner))))
                 owners))
    '()))

(def (package-node-id package)
  (string-append "package:" (project-package-name package)))

(def (extension-node-id extension)
  (string-append "extension:" (extension-fact-name extension)))

(def (owner-node-id file)
  (string-append "owner:" (source-file-path file)))

(def (package-node-snapshot package)
  (list 'node
        (list 'id (package-node-id package))
        (list 'kind "package")
        (list 'path (project-package-path package))
        (list 'fields
              (list 'name (project-package-name package))
              (list 'packageManager (project-package-manager package))
              (list 'dependencies (snapshot-list (project-package-dependencies package))))))

(def (extension-node-snapshot extension)
  (list 'node
        (list 'id (extension-node-id extension))
        (list 'kind "extension")
        (list 'fields
              (list 'name (extension-fact-name extension))
              (list 'activation (extension-fact-activation extension))
              (list 'dependencyMode (extension-fact-dependency-mode extension))
              (list 'packageManager (extension-fact-package-manager extension))
              (list 'package (extension-fact-package extension))
              (list 'dependencies (snapshot-list (extension-fact-dependencies extension)))
              (list 'capabilities (snapshot-list (extension-fact-capabilities extension))))))

(def (owner-node-snapshot file rank)
  (list 'node
        (list 'id (owner-node-id file))
        (list 'kind "owner")
        (list 'path (source-file-path file))
        (list 'rank rank)
        (owner-fields-snapshot file)))

(def (owner-snapshot file)
  (list 'owner
        (list 'path (source-file-path file))
        (list 'role "source")
        (list 'public #t)
        (list 'exports (source-file-exports file))
        (owner-fields-snapshot file)))

(def (owner-fields-snapshot file)
  (list 'fields
        (list 'package (or (source-file-package file) ""))
        (list 'definitions (length (source-file-definitions file)))
        (list 'imports (length (source-file-imports file)))
        (list 'includes (length (source-file-includes file)))))

(def (owner-hit-snapshot file rank)
  (list 'hit
        (list 'kind "owner")
        (list 'ownerPath (source-file-path file))
        (owner-location-snapshot file)
        (list 'score rank)
        (list 'reason "ranked-owner")
        (owner-fields-snapshot file)))

(def (owner-location-snapshot file)
  (list 'location
        (list 'path (source-file-path file))
        (list 'lineRange (owner-line-range file))))

(def (owner-line-range file)
  (let (definitions (source-file-definitions file))
    (if (null? definitions)
      "1:1"
      (let (first (car definitions))
        (string-append (number->string (definition-start first))
                       ":"
                       (number->string (definition-end first)))))))

(def (map-indexed proc xs)
  (let lp ((rest xs) (rank 1) (out '()))
    (match rest
      ([] (reverse out))
      ([hd . tl] (lp tl (fx1+ rank) (cons (proc hd rank) out))))))

(def (snapshot-project-root index)
  (let* ((root (trim-trailing-slash (project-index-root index)))
         (cwd (current-directory)))
    (if (string-prefix? cwd root)
      (substring root (string-length cwd) (string-length root))
      root)))

(def (trim-trailing-slash path)
  (if (and (> (string-length path) 1) (string-suffix? "/" path))
    (substring path 0 (fx1- (string-length path)))
    path))

(def (snapshot-list xs)
  (map (lambda (x) x) xs))

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

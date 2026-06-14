;;; -*- Gerbil -*-
;;; Structural search interface renderer.

(import :commands/search-render
        :parser/facade
        :parser/source-class
        :protocol/json
        :support/args
        :support/list)

(export emit-structural-index)

;;; Boundary:
;;; - emit-structural-index routes interface, owner facts, and explicit artifacts.
;;; - Default output stays lightweight so ASP Rust owns full index construction.
;; Integer <- ProjectIndex (List String) Json
(def (emit-structural-index index args json?)
  (let ((owner (option "--owner" args))
        (artifact? (or (flag? "--artifact" args) (flag? "--full" args))))
    (cond
     (owner (emit-structural-owner-facts index owner json?))
     (artifact? (emit-structural-artifact index json?))
     (else (emit-structural-interface index json?)))))

;;; Interface mode reports stable owner handles, counts, and consumer commands.
;;; The hot path must not materialize workspace syntaxFacts.
;;; ASP Rust fans out owner facts through --owner.
;;; ASP Rust owns graph topology, cache state, and ranking.
;; Integer <- ProjectIndex Json
(def (emit-structural-interface index json?)
  (let* ((packet (structural-index-packet-json index))
         (file-hashes (hash-get packet 'fileHashes))
         (owners (hash-get packet 'owners))
         (symbols (hash-get packet 'symbols))
         (summaries (hash-get packet 'nativeSyntaxFactSummaries))
         (fact-interface (hash-get packet 'factInterface))
         (dependency-usages (hash-get packet 'dependencyUsages)))
    (if json?
      (write-json-line packet)
      (begin
        (displayln "[gerbil-search-structural] root=" (project-index-root index)
                   " generationId=" (hash-get packet 'generationId)
                   " mode=" (hash-get packet 'indexMode)
                   " files=" (length file-hashes)
                   " owners=" (length owners)
                   " symbols=" (length symbols)
                   " syntaxFacts=" (hash-get packet 'nativeSyntaxFactTotal)
                   " dependencyUsages=" (length dependency-usages))
        (displayln "|artifact id=" (hash-get packet 'sourceArtifactId)
                   " schemaId=" (hash-get packet 'schemaId)
                   " rawSourceStored=false")
        (displayln "|factInterface mode=" (hash-get fact-interface 'mode)
                   " granularity=" (hash-get fact-interface 'granularity)
                   " indexOwner=" (hash-get fact-interface 'indexOwner)
                   " heavyIndexOwner=" (hash-get fact-interface 'heavyIndexOwner)
                   " graphTurboOwner=" (hash-get fact-interface 'graphTurboOwner)
                   " factSchemaId=" (hash-get fact-interface 'factSchemaId))
        (displayln "|projectionVocabulary facts=macroFacts,bindingFacts,pooFormFacts,higherOrderFacts,controlFlowFacts,predicateFamilyFacts,fieldAccessPatternFacts,booleanConditionFacts,loopDriverFacts,dependencyAdapterQualityFacts,functionQualityProfiles,typedContractFacts,commentQualityFacts,dependencyUsageFacts"
                   " consumer=asp-rust-structural-index"
                   " graphTurbo=asp-graph-turbo")
        (for-each
         (lambda (owner)
           (displayln "|owner path=" (hash-get owner 'ownerPath)
                      " kind=" (hash-get owner 'ownerKind)
                      " authority=" (hash-get owner 'sourceAuthority)
                      " sourceClass="
                      (source-path-class (hash-get owner 'ownerPath))))
         (take* owners 20))
        (for-each
         (lambda (summary)
           (displayln "|ownerFactSummary path=" (hash-get summary 'ownerPath)
                      " facts=" (hash-get summary 'facts)
                      " command=\""
                      (hash-get summary 'ownerFactsCommand)
                      "\""))
         (take* summaries 20))
        (displayln "nextCommand=gerbil-scheme-harness search structural --owner <path> --json ."))))
  0)

;;; Owner mode projects one source file's parser facts for ASP-side fan-out.
;;; It may render native facts, but it never builds the workspace artifact or
;;; graph/index topology inside the Scheme provider.
;; Integer <- ProjectIndex OwnerPath Json
(def (emit-structural-owner-facts index owner json?)
  (let (file (find-owner index owner))
    (unless file (error "owner not found" owner))
    (let* ((packet (native-syntax-owner-facts-packet-json index file))
           (facts (hash-get packet 'facts)))
      (if json?
        (write-json-line packet)
        (begin
          (displayln "[gerbil-search-structural-owner] root="
                     (project-index-root index)
                     " owner=" (source-file-path file)
                     " facts=" (length facts)
                     " schemaId=" (hash-get packet 'schemaId))
          (emit-structural-syntax-fact-lines facts)
          (displayln "nextCommand=gerbil-scheme-harness query --selector <path:start-end> --workspace . --code")))))
  0)

;;; Artifact mode is explicit validation/debug transport.
;;; The complete syntaxFacts packet remains available for schema tests, but it
;;; is not the agent-facing default and is not part of the hot performance path.
;; Integer <- ProjectIndex Json
(def (emit-structural-artifact index json?)
  (let* ((packet (structural-index-artifact-packet-json index))
         (file-hashes (hash-get packet 'fileHashes))
         (owners (hash-get packet 'owners))
         (symbols (hash-get packet 'symbols))
         (syntax-facts (hash-get packet 'syntaxFacts))
         (dependency-usages (hash-get packet 'dependencyUsages)))
    (if json?
      (write-json-line packet)
      (begin
        (displayln "[gerbil-search-structural-artifact] root="
                   (project-index-root index)
                   " generationId=" (hash-get packet 'generationId)
                   " mode=" (hash-get packet 'indexMode)
                   " files=" (length file-hashes)
                   " owners=" (length owners)
                   " symbols=" (length symbols)
                   " syntaxFacts=" (length syntax-facts)
                   " dependencyUsages=" (length dependency-usages))
        (displayln "|artifact id=" (hash-get packet 'sourceArtifactId)
                   " schemaId=" (hash-get packet 'schemaId)
                   " rawSourceStored=false")
        (emit-structural-syntax-fact-lines syntax-facts)
        (displayln "nextCommand=gerbil-scheme-harness search structural --owner <path> --json ."))))
  0)

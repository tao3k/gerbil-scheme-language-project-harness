;;; -*- Gerbil -*-
;;; JSON projections for Gerbil parser-owned facts.

(import :gerbil/gambit
        :constants
        :extensions/facade
        :parser/facade
        :parser/query
        :support/list
        :std/misc/ports
        :std/text/json
        :types/facade)

(export source-file-json
        project-package-json
        search-prime-packet-json
        structural-index-packet-json
        pattern-mapping-json
        definition-json
        top-form-json
        finding-json
        parse-error-json
        write-json-line)

(def +semantic-search-schema-id+
  "agent.semantic-protocols.semantic-search-packet")
(def +semantic-structural-index-schema-id+
  "agent.semantic-protocols.semantic-structural-index")
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")
(def +semantic-namespace+
  "agent.semantic-protocols.gerbil-scheme")

(def (source-file-json file)
  (hash (path (source-file-path file))
        (package (source-file-package file))
        (prelude (source-file-prelude file))
        (namespace (source-file-namespace file))
        (imports (source-file-imports file))
        (exports (source-file-exports file))
        (includes (source-file-includes file))
        (definitions (map definition-json (source-file-definitions file)))
        (forms (map top-form-json (source-file-forms file)))
        (parseError (source-file-parse-error file))))

(def (project-package-json package)
  (and package
       (hash (path (project-package-path package))
             (name (project-package-name package))
             (dependencies (project-package-dependencies package))
             (fields (hash (packageManager (project-package-manager package))
                           (testDirectoryPolicy
                            (test-directory-policy-json
                             (project-package-test-directory-policy package))))))))

(def (test-directory-policy-json policy)
  (and policy
       (hash (allowedDirectories
              (test-directory-policy-allowed-directories policy))
             (explanation
              (test-directory-policy-explanation policy)))))

(def (pattern-mapping-json pattern)
  (and pattern
       (hash (id (hash-get pattern 'id))
             (extension (hash-get pattern 'extension))
             (focus (hash-get pattern 'focus))
             (sourceRef (hash-get pattern 'sourceRef))
             (sourceOwners (hash-get pattern 'sourceOwners))
             (agentScenario (hash-get pattern 'agentScenario))
             (intent (hash-get pattern 'intent))
             (selectors (map pattern-selector-json
                             (hash-get pattern 'selectors)))
             (minimalForms (map pattern-form-json
                                (hash-get pattern 'minimalForms)))
             (failureCases (map pattern-failure-case-json
                                 (hash-get pattern 'failureCases)))
             (qualitySignals (hash-get pattern 'qualitySignals))
             (witness (hash-get pattern 'witness)))))

(def (pattern-selector-json selector)
  (hash (role (hash-get selector 'role))
        (symbol (hash-get selector 'symbol))
        (selector (hash-get selector 'selector))))

(def (pattern-form-json form)
  (hash (role (hash-get form 'role))
        (symbol (hash-get form 'symbol))
        (selector (hash-get form 'selector))
        (template (pattern-form-template-json
                   (hash-get form 'template)))))

(def (pattern-form-template-json template)
  (hash (head (hash-get template 'head))
        (operands (hash-get template 'operands))
        (keywords (hash-get template 'keywords))))

(def (pattern-failure-case-json failure)
  (let (packet (hash (id (hash-get failure 'id))))
    (if (hash-key? failure 'riskKind)
      (begin
        (hash-put! packet 'riskKind (hash-get failure 'riskKind))
        (hash-put! packet 'correctiveAction (hash-get failure 'correctiveAction)))
      (begin
        (hash-put! packet 'risk (hash-get failure 'risk))
        (hash-put! packet 'correction (hash-get failure 'correction))))
    (when (hash-key? failure 'badPattern)
      (hash-put! packet 'badPattern (hash-get failure 'badPattern)))
    (hash-put! packet 'selectors
               (if (hash-key? failure 'selectors)
                 (hash-get failure 'selectors)
                 []))
    packet))

(def (search-prime-packet-json index)
  (let* ((owners (take* (ranked-files index) 100))
         (package (project-index-package index))
         (extensions (project-extension-facts index))
         (packet
          (hash
           (schemaId +semantic-search-schema-id+)
           (schemaVersion "1")
           (protocolId +semantic-language-protocol-id+)
           (protocolVersion "1")
           (languageId +language-id+)
           (providerId +provider-id+)
           (binary +provider-id+)
           (namespace +semantic-namespace+)
           (method "search/prime")
           (projectRoot (project-index-root index))
           (view "prime")
           (renderMode "facts")
           (header (search-header-json index))
           (nodes (search-prime-nodes package extensions owners))
           (edges (search-prime-edges package extensions owners))
           (owners (map owner-json owners))
           (hits (map-indexed owner-hit-json owners))
           (findings '())
           (nextActions (list (hash (kind "search")
                                    (target "fzf")
                                    (scope (project-index-root index))
                                    (fields (hash (command
                                                   "gerbil-scheme-harness search fzf '<term>' owner tests --view seeds ."))))))
           (notes (list (hash (kind "parser")
                              (message "core-read-module native Scheme reader facts")))))))
    (when package
      (hash-put! packet 'packageName (project-package-name package))
      (hash-put! packet 'projectPackage (project-package-json package)))
    (hash-put! packet 'extensions (map extension-fact-json extensions))
    packet))

(def (structural-index-packet-json index)
  (let* ((generation-id (structural-index-generation-id index))
         (artifact-id (string-append "structural-index/" generation-id ".json"))
         (files (project-index-files index)))
    (hash
     (schemaId +semantic-structural-index-schema-id+)
     (schemaVersion "1")
     (protocolId +semantic-language-protocol-id+)
     (protocolVersion "1")
     (generationId generation-id)
     (languageId +language-id+)
     (providerId +provider-id+)
     (providerVersion "0.1.0")
     (exportMethod "index/structural")
     (projectRoot (project-index-root index))
     (packageRoot ".")
     (sourceAuthority "native-parser")
     (sourceArtifactId artifact-id)
     (rawSourceStored #f)
     (fileHashes (map (cut structural-file-hash-json index <>) files))
     (owners (map structural-owner-json files))
     (symbols (append-map* structural-symbol-json files))
     (dependencyUsages (append-map* structural-dependency-json files)))))

(def (structural-index-generation-id index)
  (string-append
   +language-id+
   "-structural-"
   (substring (stable-hex64
               (join (map (cut structural-file-fingerprint index <>)
                          (project-index-files index))
                     "|"))
              0
              16)))

(def (structural-file-hash-json index file)
  (hash (path (source-file-path file))
        (sha256 (structural-file-fingerprint index file))
        (source "native-parser-fingerprint")))

(def (structural-file-fingerprint index file)
  (with-catch
   (lambda (_)
     (stable-hex64 (structural-file-fact-string file)))
   (lambda ()
     (stable-hex64
      (join (read-file-lines
             (path-expand (source-file-path file)
                          (project-index-root index)))
            "\n")))))

(def (structural-file-fact-string file)
  (join [(source-file-path file)
         (number->string (source-file-line-count file))
         (or (source-file-package file) "")
         (or (source-file-namespace file) "")
         (join (source-file-imports file) ",")
         (join (source-file-exports file) ",")
         (join (map definition-name (source-file-definitions file)) ",")
         (join (map call-fact-callee (source-file-calls file)) ",")]
        "|"))

(def (structural-owner-json file)
  (hash (ownerPath (source-file-path file))
        (ownerKind "source")
        (sourceAuthority "native-parser")
        (location (hash (path (source-file-path file))
                        (lineRange (string-append
                                    "1:"
                                    (number->string
                                     (max 1 (source-file-line-count file)))))))
        (queryKeys (dedupe (append [(source-file-path file)]
                                   (if (source-file-package file)
                                     [(source-file-package file)]
                                     '())
                                   (source-file-imports file)
                                   (map definition-name
                                        (source-file-definitions file)))))))

(def (structural-symbol-json file)
  (map (lambda (defn)
         (hash (ownerPath (definition-path defn))
               (name (definition-name defn))
               (qualifiedName (structural-qualified-name file defn))
               (kind (definition-kind defn))
               (visibility (if (member (definition-name defn)
                                       (source-file-exports file))
                             "public"
                             "private"))
               (sourceLocator (definition-selector defn))
               (queryKeys (dedupe [(definition-name defn)
                                   (structural-qualified-name file defn)
                                   (definition-kind defn)
                                   (definition-path defn)]))))
       (source-file-definitions file)))

(def (structural-qualified-name file defn)
  (let (ns (or (source-file-namespace file)
               (source-file-package file)
               (source-file-path file)))
    (string-append ns "::" (definition-name defn))))

(def (structural-dependency-json file)
  (append
   (map (lambda (module-ref)
          (structural-dependency-row file module-ref "native-parser-import"))
        (source-file-imports file))
   (map (lambda (include-ref)
          (structural-dependency-row file include-ref "native-parser-include"))
        (source-file-includes file))))

(def (structural-dependency-row file module-ref source)
  (hash (ownerPath (source-file-path file))
        (packageName module-ref)
        (apiName module-ref)
        (importPath module-ref)
        (manifestPath "gerbil.pkg")
        (source source)
        (sourceLocator (string-append (source-file-path file) ":1:1"))
        (queryKeys (dedupe [module-ref (source-file-path file) source]))))

(def (search-header-json index)
  (hash (kind "search-prime")
        (fields (hash (parser "core-read-module")
                      (files (length (project-index-files index)))
                      (definitions (length (project-definitions index)))))))

(def (search-prime-nodes package extensions owners)
  (append (if package (list (package-node-json package)) '())
          (map extension-node-json extensions)
          (map-indexed owner-node-json owners)))

(def (search-prime-edges package extensions owners)
  (if package
    (append (map (lambda (extension)
                   (hash (from (package-node-id package))
                         (kind "activates")
                         (to (extension-node-id extension))))
                 extensions)
            (map (lambda (owner)
                   (hash (from (package-node-id package))
                         (kind "owns")
                         (to (owner-node-id owner))))
                 owners))
    '()))

(def (package-node-id package)
  (string-append "package:" (project-package-name package)))

(def (extension-node-id extension)
  (string-append "extension:" (extension-fact-name extension)))

(def (owner-node-id file)
  (string-append "owner:" (source-file-path file)))

(def (package-node-json package)
  (hash (id (package-node-id package))
        (kind "package")
        (path (project-package-path package))
        (fields (hash (name (project-package-name package))
                      (packageManager (project-package-manager package))
                      (dependencies (project-package-dependencies package))))))

(def (extension-node-json extension)
  (hash (id (extension-node-id extension))
        (kind "extension")
        (fields (hash (name (extension-fact-name extension))
                      (activation (extension-fact-activation extension))
                      (dependencyMode (extension-fact-dependency-mode extension))
                      (packageManager (extension-fact-package-manager extension))
                      (package (extension-fact-package extension))
                      (dependencies (extension-fact-dependencies extension))
                      (capabilities (extension-fact-capabilities extension))))))

(def (owner-node-json file rank)
  (hash (id (owner-node-id file))
        (kind "owner")
        (path (source-file-path file))
        (rank rank)
        (fields (owner-fields-json file))))

(def (owner-json file)
  (hash (path (source-file-path file))
        (role "source")
        (public #t)
        (exports (source-file-exports file))
        (fields (owner-fields-json file))))

(def (owner-fields-json file)
  (hash (package (or (source-file-package file) ""))
        (definitions (length (source-file-definitions file)))
        (imports (length (source-file-imports file)))
        (includes (length (source-file-includes file)))))

(def (owner-hit-json file rank)
  (hash (kind "owner")
        (ownerPath (source-file-path file))
        (location (owner-location-json file))
        (score rank)
        (reason "ranked-owner")
        (fields (owner-fields-json file))))

(def (owner-location-json file)
  (hash (path (source-file-path file))
        (lineRange (owner-line-range file))))

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

(def (append-map* proc xs)
  (if (null? xs)
    '()
    (append (proc (car xs)) (append-map* proc (cdr xs)))))

(def (stable-hex64 text)
  (let (chunk (left-pad-hex (number->string (stable-hash text) 16) 16))
    (string-append chunk chunk chunk chunk)))

(def (stable-hash text)
  (let lp ((chars (string->list text)) (hash 2166136261))
    (match chars
      ([] hash)
      ([ch . rest]
       (lp rest (modulo (+ (* hash 16777619) (char->integer ch))
                        4294967296))))))

(def (left-pad-hex text width)
  (if (fx>= (string-length text) width)
    text
    (left-pad-hex (string-append "0" text) width)))

(def (definition-json defn)
  (hash (name (definition-name defn))
        (kind (definition-kind defn))
        (path (definition-path defn))
        (start (definition-start defn))
        (end (definition-end defn))
        (formals (definition-formals defn))
        (arity (definition-arity defn))
        (selector (definition-selector defn))))

(def (top-form-json form)
  (hash (kind (top-form-kind form))
        (head (top-form-head form))
        (path (top-form-path form))
        (start (top-form-start form))
        (end (top-form-end form))
        (selector (top-form-selector form))))

(def (finding-json finding)
  (hash (ruleId (type-finding-rule-id finding))
        (severity (type-finding-severity finding))
        (path (type-finding-path finding))
        (message (type-finding-message finding))
        (selector (type-finding-selector finding))
        (details (type-finding-details finding))))

(def (parse-error-json file)
  (hash (path (source-file-path file))
        (ruleId "GERBIL-SCHEME-READ-R001")
        (message (source-file-parse-error file))))

(def (write-json-line obj)
  (write-json obj)
  (newline))

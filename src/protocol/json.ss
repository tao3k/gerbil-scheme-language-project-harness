;;; -*- Gerbil -*-
;;; JSON projections for Gerbil parser-owned facts.

(import :constants
        :extensions/facade
        :parser/facade
        :parser/query
        :support/list
        :std/text/json
        :types/facade)

(export source-file-json
        project-package-json
        search-prime-packet-json
        definition-json
        top-form-json
        finding-json
        parse-error-json
        write-json-line)

(def +semantic-search-schema-id+
  "agent.semantic-protocols.semantic-search-packet")
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
             (fields (hash (packageManager (project-package-manager package)))))))

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

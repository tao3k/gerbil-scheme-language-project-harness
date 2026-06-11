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

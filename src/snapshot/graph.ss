;;; -*- Gerbil -*-
;;; Stable evidence graph snapshot projections.

(import :constants
        :extensions/facade
        :parser/facade
        :parser/query
        :snapshot/core
        :snapshot/support
        :support/list)

(export extension-packet-snapshot
        search-prime-snapshot)
;;; Boundary:
;;; - extension-packet-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; JsonPacket <- ProjectIndex
(def (extension-packet-snapshot index)
  (list 'extensionPacket
        (project-package-snapshot (project-index-package index))
        (list 'extensions
              (map extension-fact-snapshot (project-extension-facts index)))
        (list 'searchLines (project-extension-search-lines index))))
;;; Boundary:
;;; - search-prime-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Snapshot <- ProjectIndex
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
                                        "gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")))))
          (list 'notes
                (list (list 'note
                            (list 'kind "parser")
                            (list 'message "core-read-module native Scheme reader facts")))))))
;; Snapshot <- ProjectIndex
(def (search-header-snapshot index)
  (list 'header
        (list 'kind "search-prime")
        (list 'fields
              (list 'parser "core-read-module")
              (list 'files (length (project-index-files index)))
              (list 'definitions (length (project-definitions index))))))
;;; Boundary:
;;; - search-prime-node-snapshots composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Snapshot <- Package Extensions (List XX)
(def (search-prime-node-snapshots package extensions owners)
  (append (if package (list (package-node-snapshot package)) '())
          (map extension-node-snapshot extensions)
          (map-indexed owner-node-snapshot owners)))
;;; Boundary:
;;; - search-prime-edge-snapshots composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Snapshot <- Package Extensions (List XX)
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
;; String <- Package
(def (package-node-id package)
  (string-append "package:" (project-package-name package)))
;; String <- Extension
(def (extension-node-id extension)
  (string-append "extension:" (extension-fact-name extension)))
;; String <- SourceFile
(def (owner-node-id file)
  (string-append "owner:" (source-file-path file)))
;; Snapshot <- Package
(def (package-node-snapshot package)
  (list 'node
        (list 'id (package-node-id package))
        (list 'kind "package")
        (list 'path (project-package-path package))
        (list 'fields
              (list 'name (project-package-name package))
              (list 'packageManager (project-package-manager package))
              (list 'dependencies (snapshot-list (project-package-dependencies package))))))
;; Snapshot <- Extension
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
;; Snapshot <- SourceFile Integer
(def (owner-node-snapshot file rank)
  (list 'node
        (list 'id (owner-node-id file))
        (list 'kind "owner")
        (list 'path (source-file-path file))
        (list 'rank rank)
        (owner-fields-snapshot file)))
;; Snapshot <- SourceFile
(def (owner-snapshot file)
  (list 'owner
        (list 'path (source-file-path file))
        (list 'role "source")
        (list 'public #t)
        (list 'exports (source-file-exports file))
        (owner-fields-snapshot file)))
;; Snapshot <- SourceFile
(def (owner-fields-snapshot file)
  (list 'fields
        (list 'package (or (source-file-package file) ""))
        (list 'definitions (length (source-file-definitions file)))
        (list 'imports (length (source-file-imports file)))
        (list 'includes (length (source-file-includes file)))))
;; Snapshot <- SourceFile Integer
(def (owner-hit-snapshot file rank)
  (list 'hit
        (list 'kind "owner")
        (list 'ownerPath (source-file-path file))
        (owner-location-snapshot file)
        (list 'score rank)
        (list 'reason "ranked-owner")
        (owner-fields-snapshot file)))
;; Snapshot <- SourceFile
(def (owner-location-snapshot file)
  (list 'location
        (list 'path (source-file-path file))
        (list 'lineRange (owner-line-range file))))
;; OwnerLineRange <- SourceFile
(def (owner-line-range file)
  (let (definitions (source-file-definitions file))
    (if (null? definitions)
      "1:1"
      (let (first (car definitions))
        (string-append (number->string (definition-start first))
                       ":"
                       (number->string (definition-end first)))))))

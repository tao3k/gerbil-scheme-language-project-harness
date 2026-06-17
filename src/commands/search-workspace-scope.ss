;;; -*- Gerbil -*-
;;; Lightweight parser-owned workspace scope renderer.

(import :parser/facade
        :protocol/json
        :protocol/workspace-scope
        :support/list
        (only-in :std/sort sort))

(export emit-workspace-scope)

;; Integer
(def +workspace-scope-preview-limit+ 24)

;;; Boundary:
;;; - Workspace scope discovery belongs to the language provider.
;;; - This path reads package policy and walks provider-owned source roots only.
;;; - It intentionally avoids parsing source forms or building SQL/graph indexes.
;; Integer <- Root Json
(def (emit-workspace-scope root json?)
  (let* ((package-index (collect-project-package-only root))
         (root (project-index-root package-index))
         (package (project-index-package package-index))
         (files (if package
                  (sort (collect-source-files root package) string<?)
                  '()))
         (packet (workspace-scope-packet-json root package files)))
    (if json?
      (write-json-line packet)
      (emit-workspace-scope-lines packet))
    0))

;; Unit <- Json
(def (emit-workspace-scope-lines packet)
  (let* ((coverage (hash-get packet 'coverage))
         (anchor (hash-get packet 'anchor))
         (files (hash-get packet 'files)))
    (displayln "[gerbil-workspace-scope] root=" (hash-get packet 'projectRoot)
               " status=" (hash-get packet 'status)
               " files=" (length files)
               " scopeOwner=" (hash-get packet 'scopeOwner)
               " indexOwner=" (hash-get packet 'indexOwner))
    (displayln "|anchor path=" (hash-get anchor 'path)
               " packageManager=" (hash-get anchor 'packageManager)
               " packageName=" (or (hash-get anchor 'packageName) "-"))
    (displayln "|coverage configFiles="
               (join-or-dash (hash-get coverage 'configFiles))
               " sourceExtensions="
               (join-or-dash (hash-get coverage 'sourceExtensions))
               " sourceRoots="
               (join-or-dash (hash-get coverage 'sourceRoots))
               " runtimeRoots="
               (join-or-dash (hash-get coverage 'runtimeRoots))
               " ignoredPathPrefixes="
               (join-or-dash (hash-get coverage 'ignoredPathPrefixes)))
    (for-each
     (lambda (file)
       (displayln "|file path=" (hash-get file 'path)
                  " sourceClass=" (hash-get file 'sourceClass)
                  " sourceKind=" (hash-get file 'sourceKind)))
     (take* files +workspace-scope-preview-limit+))
    (displayln "nextCommand=asp cache source-index refresh")))

;; String <- (List String)
(def (join-or-dash values)
  (if (null? values)
    "-"
    (join values ",")))

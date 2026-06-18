;;; -*- Gerbil -*-
;;; Lightweight parser-owned workspace scope renderer.

(import (only-in :commands/search-render join-or-dash)
        :parser/facade
        :protocol/json
        :protocol/workspace-scope
        :support/io
        (only-in :std/sort sort)
        (only-in :std/srfi/1 take))

(export emit-workspace-scope)

;; Integer
(def +workspace-scope-preview-limit+ 24)

;;; Boundary:
;;; - Workspace scope discovery belongs to the language provider.
;;; - This path reads package policy and walks provider-owned source roots only.
;;; - It intentionally avoids parsing source forms or building SQL/graph indexes.
;; : (-> Root Json Integer )
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

;;; Boundary:
;;; - The renderer consumes an already-scoped packet and must not rediscover files.
;;; - Keep line order stable because agents use it as the first workspace receipt.
;; : (-> Json Unit )
(def (emit-workspace-scope-lines packet)
  (let* ((coverage (hash-get packet 'coverage))
         (anchor (hash-get packet 'anchor))
         (files (hash-get packet 'files)))
    (emit-field-line
     "[gerbil-workspace-scope]"
     [(line-field "root" (hash-get packet 'projectRoot))
      (line-field "status" (hash-get packet 'status))
      (line-field "files" (length files))
      (line-field "scopeOwner" (hash-get packet 'scopeOwner))
      (line-field "indexOwner" (hash-get packet 'indexOwner))])
    (emit-field-line
     "|anchor"
     [(line-field "path" (hash-get anchor 'path))
      (line-field "packageManager" (hash-get anchor 'packageManager))
      (line-field "packageName" (or (hash-get anchor 'packageName) "-"))])
    (emit-field-line
     "|coverage"
     [(line-field "configFiles" (join-or-dash (hash-get coverage 'configFiles)))
      (line-field "sourceExtensions" (join-or-dash (hash-get coverage 'sourceExtensions)))
      (line-field "sourceRoots" (join-or-dash (hash-get coverage 'sourceRoots)))
      (line-field "runtimeRoots" (join-or-dash (hash-get coverage 'runtimeRoots)))
      (line-field "ignoredPathPrefixes" (join-or-dash (hash-get coverage 'ignoredPathPrefixes)))])
    (for-each
     (lambda (file)
       (emit-field-line
        "|file"
        [(line-field "path" (hash-get file 'path))
         (line-field "sourceClass" (hash-get file 'sourceClass))
         (line-field "sourceKind" (hash-get file 'sourceKind))]))
     (take files (min +workspace-scope-preview-limit+ (length files))))
    (emit-text-line "nextCommand=asp cache source-index refresh")))

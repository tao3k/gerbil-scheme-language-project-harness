;;; -*- Gerbil -*-
;;; Lightweight prime-seeds renderer for the Gerbil search command.

(import :constants
        :parser/package
        :parser/source-class
        :parser/source-scope
        :support/args
        (only-in :std/sort sort)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13 string-index-right string-join string-prefix?)
        (only-in :std/sugar hash match))

(export search-prime-light-main
        search-workspace-scope-light-main
        emit-prime-light)

;; Integer
(def +prime-light-preview-limit+ 12)

;; String
(def +semantic-workspace-scope-schema-id+
  "agent.semantic-protocols.semantic-workspace-scope")
;; String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")

;;; Boundary:
;;; - This command path is intentionally package/source-scope only.
;;; - ASP owns dependency source indexing, route topology, symbol indexes, and
;;;   reasoning-tree state built from this provider-owned workspace map.
;; : (-> Args Integer )
(def (search-prime-light-main args)
  (match args
    (["prime" . rest]
     (let* ((root (path-normalize (project-root rest)))
            (args (drop-project-root rest))
            (json? (flag? "--json" args)))
       (if json?
         (error "search prime light does not render json")
         (emit-prime-light root))))
    (else (error "search-prime-light requires prime view"))))

;;; Boundary:
;;; - Workspace scope is the provider-owned topology seed.
;;; - The provider reports package/source policy; ASP builds the heavy source
;;;   index and dependency navigation structures from the packet.
;; : (-> Args Integer )
(def (search-workspace-scope-light-main args)
  (match args
    (["workspace-scope" . rest]
     (let* ((root (path-normalize (project-root rest)))
            (args (drop-project-root rest))
            (json? (flag? "--json" args)))
       (emit-workspace-scope-light root json?)))
    (else (error "search-workspace-scope-light requires workspace-scope view"))))

;;; Boundary:
;;; - The seed packet exposes durable navigation facts only.
;;; - It must not parse source forms or produce graph-derived rank.
;; : (-> Root Integer )
(def (emit-prime-light root)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (source-files-light root package)))
    (displayln "[gerbil-search-prime] root=" root
               " files=" (length files)
               " definitions=skipped"
               " analysis=structure"
               " nativeSyntaxFacts=skipped"
               " topology=asp-owned")
    (displayln "|language id=" +language-id+ " provider=" +provider-id+
               " parser=package-manager")
    (emit-package-line-light package)
    (displayln "|factScope sourceForms=skipped graphRank=asp-owned sourceIndex=asp-owned")
    (for-each
     (lambda (path)
       (let (owner (relative-owner-path root path))
         (displayln "owner:path(" owner ")"
                    " package=" (or (and package (project-package-name package)) "-")
                    " sourceClass=" (source-path-class owner)
                    " defs=skipped"
                    " imports=skipped"
                    " next=owner:" owner)))
     (take files (min +prime-light-preview-limit+ (length files))))
    (displayln "recommendedNext=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")
    (displayln "nextCommand=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds"))
  0)

;; : (-> Root Boolean Integer )
(def (emit-workspace-scope-light root json?)
  (if json?
    (error "search workspace-scope light does not render json")
    (let* ((root (path-normalize root))
           (package (read-project-package root))
           (files (source-files-light root package))
           (packet (workspace-scope-packet-light root package files)))
      (emit-workspace-scope-lines-light packet)
      0)))

;; : (-> Root MaybePackage (List Path) Json )
(def (workspace-scope-packet-light root package files)
  (let* ((policy (and package
                      (project-package-source-scope-policy package)))
         (source-roots (workspace-source-roots policy))
         (runtime-roots (workspace-runtime-roots policy))
         (exclude-directories (workspace-exclude-directories policy))
         (status (if package "ready" "missing-anchor")))
    (hash
     (schemaId +semantic-workspace-scope-schema-id+)
     (schemaVersion "1")
     (protocolId +semantic-language-protocol-id+)
     (protocolVersion "1")
     (languageId +language-id+)
     (providerId +provider-id+)
     (projectRoot root)
     (packageRoot ".")
     (status status)
     (sourceAuthority "language-provider-workspace-scope")
     (scopeOwner +provider-id+)
     (indexOwner "asp-rust-sql-source-index")
     (rawSourceStored #f)
     (anchor (workspace-anchor-light package))
     (coverage
      (hash
       (configFiles +config-files+)
       (sourceExtensions +source-extensions+)
       (sourceRoots source-roots)
       (runtimeRoots runtime-roots)
       (ignoredPathPrefixes (append +ignored-dirs+ exclude-directories))
       (policyExplanation (and policy
                               (source-scope-policy-explanation policy)))))
     (files (map (lambda (path)
                   (workspace-scope-file-light root path))
                 files)))))

;; : (-> MaybePackage Json )
(def (workspace-anchor-light package)
  (if package
    (hash (path (project-package-path package))
          (packageManager (project-package-manager package))
          (packageName (project-package-name package)))
    (hash (path "missing")
          (packageManager "gxpkg")
          (packageName #f))))

;; : (-> Root Path Json )
(def (workspace-scope-file-light root path)
  (let* ((owner (relative-owner-path root path))
         (source-class (source-path-class owner)))
    (hash (path owner)
          (sourceClass source-class)
          (sourceKind (if (equal? source-class "config")
                        "config"
                        "source"))
          (languageId +language-id+)
          (providerId +provider-id+))))

;; : (-> Json Unit )
(def (emit-workspace-scope-lines-light packet)
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
    (displayln "|coverage configFiles=" (join-or-dash (hash-get coverage 'configFiles))
               " sourceExtensions=" (join-or-dash (hash-get coverage 'sourceExtensions))
               " sourceRoots=" (join-or-dash (hash-get coverage 'sourceRoots))
               " runtimeRoots=" (join-or-dash (hash-get coverage 'runtimeRoots))
               " ignoredPathPrefixes=" (join-or-dash (hash-get coverage 'ignoredPathPrefixes)))
    (for-each
     (lambda (file)
       (displayln "|file path=" (hash-get file 'path)
                  " sourceClass=" (hash-get file 'sourceClass)
                  " sourceKind=" (hash-get file 'sourceKind)))
     (take files (min 24 (length files))))
    (displayln "nextCommand=asp cache source-index refresh")))

;; : (-> Root MaybePackage (List Path) )
(def (source-files-light root package)
  (if package
    (sort (collect-source-files root package) string<?)
    '()))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-source-roots policy)
  (let (roots (and policy (source-scope-policy-roots policy)))
    (if (and roots (pair? roots)) roots ["."])))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-runtime-roots policy)
  (let (roots (and policy (source-scope-policy-runtime-roots policy)))
    (if roots roots '())))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-exclude-directories policy)
  (let (dirs (and policy (source-scope-policy-exclude-directories policy)))
    (if dirs dirs '())))

;; : (-> (List String) String )
(def (join-or-dash values)
  (if (and values (pair? values))
    (string-join values ",")
    "-"))

;; : (-> MaybePackage Unit )
(def (emit-package-line-light package)
  (when package
    (displayln "|package name=" (or (project-package-name package) "-")
               " path=" (project-package-path package)
               " packageManager=" (project-package-manager package)
               " dependencies=" (string-join (project-package-dependencies package) ","))))

;; : (-> Root Path Path )
(def (relative-owner-path root path)
  (let* ((root* (strip-trailing-path-separator (path-normalize root)))
         (path* (path-normalize path))
         (prefix (string-append root* "/")))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;; : (-> Path Path )
(def (strip-trailing-path-separator path)
  (let (last-path-char
        (string-index-right path
                            (lambda (char)
                              (not (char=? char #\/)))))
    (if (and last-path-char
             (< (fx1+ last-path-char) (string-length path)))
      (substring path 0 (fx1+ last-path-char))
      path)))

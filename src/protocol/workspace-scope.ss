;;; -*- Gerbil -*-
;;; Parser-owned workspace scope packet for Rust SQL source indexing.

(import :gerbil/gambit
        :gslph/src/constants
        :gslph/src/parser/facade
        :gslph/src/parser/selectors
        :gslph/src/parser/source-class
        (only-in :std/srfi/1 filter)
        (only-in :std/sugar hash))

(export workspace-scope-packet-json
        +semantic-workspace-scope-schema-id+)

;; String
(def +semantic-workspace-scope-schema-id+
  "agent.semantic-protocols.semantic-workspace-scope")
;; String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")

;;; Boundary:
;;; - The language provider owns package/workspace scope discovery.
;;; - ASP Rust consumes this packet to build the SQL source index.
;;; - No raw source text, tokenization, SQL rows, or graph topology are produced here.
;; : (-> Root MaybePackage (List AbsolutePath) Json )
(def (workspace-scope-packet-json root package files)
  (let* ((root (path-normalize root))
         (policy (and package
                      (project-package-source-scope-policy package)))
         (source-roots (workspace-source-roots policy))
         (runtime-roots (workspace-runtime-roots policy))
         (exclude-directories (workspace-exclude-directories policy))
         (scope-included-dirs (workspace-scope-included-dirs source-roots
                                                             runtime-roots))
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
     (anchor (workspace-anchor-json package))
     (coverage
      (hash
       (configFiles +config-files+)
       (sourceExtensions +source-extensions+)
       (sourceRoots source-roots)
       (runtimeRoots runtime-roots)
       (scopeIncludedDirs scope-included-dirs)
       (excludeDirectories exclude-directories)
       (policyExplanation (and policy
                               (source-scope-policy-explanation policy)))))
     (files (map (lambda (path)
                   (workspace-scope-file-json root path))
                 files)))))

;; : (-> MaybePackage Json )
(def (workspace-anchor-json package)
  (if package
    (hash (path (project-package-path package))
          (packageManager (project-package-manager package))
          (packageName (project-package-name package)))
    (hash (path "missing")
          (packageManager "gxpkg")
          (packageName #f))))

;; : (-> Root AbsolutePath Json )
(def (workspace-scope-file-json root path)
  (let* ((owner-path (relative-path root path))
         (source-class (source-path-class owner-path)))
    (hash (path owner-path)
          (sourceClass source-class)
          (sourceKind (if (equal? source-class "config")
                        "config"
                        "source"))
          (languageId +language-id+)
          (providerId +provider-id+))))

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

;;; Included-scope boundary:
;;; - The public packet exposes positive source/runtime roots for index seeding.
;;; - Exclude directories stay as policy metadata and are not merged with
;;;   provider-private default ignore lists.
;; : (-> (List String) (List String) (List String) )
(def (workspace-scope-included-dirs source-roots runtime-roots)
  (unique-workspace-paths (append source-roots runtime-roots)))

;;; Stable path-set boundary:
;;; - Keep first occurrence order because agents compare packet text directly.
;;; - Paths are policy strings, so string equality via member is sufficient.
;; unique-workspace-paths
;; : (-> (List String) (List String) )
;;   | doc m%
;;       `unique-workspace-paths` keeps each project-relative scope path once,
;;       in the order supplied by the package source-scope policy.
;;
;;       # Examples
;;
;;       ```scheme
;;       (unique-workspace-paths '("src" "src" "test"))
;;       ;; => ("src" "test")
;;       ```
;;     %
(def (unique-workspace-paths values)
  (if (null? values)
    '()
    (cons (car values)
          (unique-workspace-paths
           (filter (lambda (value)
                     (not (equal? value (car values))))
                   (cdr values))))))

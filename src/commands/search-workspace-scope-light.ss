;;; -*- Gerbil -*-
;;; Lightweight workspace-scope renderer for the native search launcher.

(import :gerbil/gambit
        :gslph/src/constants
        (only-in :gslph/src/commands/search-prime-light
                 drop-project-root
                 flag?
                 project-package-manager
                 project-package-name
                 project-package-path
                 project-package-source-scope-policy
                 project-root
                 read-project-package
                 relative-owner-path
                 source-path-class
                 take-up-to
                 workspace-runtime-roots
                 workspace-source-roots)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-join))

(export search-workspace-scope-light-main)

;; ConfigConstant
(def +workspace-scope-source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
;; ConfigConstant
(def +workspace-scope-config-files+ '("gerbil.pkg" "build.ss"))

;;; Boundary:
;;; - Workspace scope is the provider-owned topology seed.
;;; - The provider reports package/source policy; ASP builds the heavy source
;;;   index and dependency navigation structures from the packet.
;; : (-> Args Integer )
(def (search-workspace-scope-light-main args)
  (if (and (pair? args) (equal? (car args) "workspace-scope"))
    (let ((tail (cdr args)))
      (let ((root (path-normalize (project-root tail))))
        (let ((normalized-args (drop-project-root tail)))
          (let ((json? (flag? "--json" normalized-args)))
            (emit-workspace-scope-light root json?)))))
    (error "search-workspace-scope-light requires workspace-scope view")))

;; : (-> Root Boolean Integer )
(def (emit-workspace-scope-light root json?)
  (if json?
    (error "search workspace-scope light does not render json")
    (let* ((root (path-normalize root))
           (package (read-project-package root))
           (files (workspace-scope-preview-files-light root package)))
      (emit-workspace-scope-lines-light root package files)
      0)))

;;; Packet rendering boundary:
;;; - Workspace-scope output is a compact package/source-policy receipt.
;;; - Source indexing and dependency graph expansion remain ASP-owned.
;; : (-> MaybePackage String )
(def (workspace-scope-status package)
  (if package "ready" "missing-anchor"))
;; : (-> MaybePackage Path )
(def (workspace-scope-package-path package)
  (if package (project-package-path package) "missing"))
;; : (-> MaybePackage String )
(def (workspace-scope-package-manager package)
  (if package (project-package-manager package) "gxpkg"))
;; : (-> MaybePackage String )
(def (workspace-scope-package-name package)
  (or (and package (project-package-name package)) "-"))
;; : (-> SourceClass SourceKind )
(def (workspace-scope-source-kind source-class)
  (if (equal? source-class "config") "config" "source"))
;; : (-> Root MaybePackage (List Path) Unit )
(def (emit-workspace-scope-lines-light root package files)
  (let* ((policy (and package
                      (project-package-source-scope-policy package)))
         (source-roots (workspace-source-roots policy))
         (runtime-roots (workspace-runtime-roots policy))
         (scope-included-dirs (workspace-scope-included-dirs source-roots
                                                             runtime-roots))
         (status (workspace-scope-status package)))
    (displayln "[gerbil-workspace-scope] root=" root
               " status=" status
               " filePreview=" (length files)
               " scopeOwner=" +provider-id+
               " indexOwner=asp-rust-sql-source-index")
    (displayln "|anchor path=" (workspace-scope-package-path package)
               " packageManager=" (workspace-scope-package-manager package)
               " packageName=" (workspace-scope-package-name package))
    (displayln "|coverage configFiles=" (join-or-dash +workspace-scope-config-files+)
               " sourceExtensions=" (join-or-dash +workspace-scope-source-extensions+)
               " sourceRoots=" (join-or-dash source-roots)
               " runtimeRoots=" (join-or-dash runtime-roots)
               " scopeIncludedDirs=" (join-or-dash scope-included-dirs))
    (for-each
     (lambda (path)
       (let* ((owner (relative-owner-path root path))
              (source-class (source-path-class owner)))
         (displayln "|file path=" owner
                    " sourceClass=" source-class
                    " sourceKind=" (workspace-scope-source-kind source-class))))
     (take-up-to files 24))
    (displayln "nextCommand=asp cache source-index refresh")))

;;; Config preview boundary:
;;; - Workspace-scope starts from package anchors, not a source walk.
;;; - Full source indexing remains delegated to ASP after this packet.
;; : (-> Root MaybePackage (List Path) )
(def (workspace-scope-preview-files-light root package)
  (if package
    (map (lambda (path)
           (path-normalize (path-expand path root)))
         +workspace-scope-config-files+)
    '()))

;;; Included-scope boundary:
;;; - Source and runtime roots are the only positive directories exposed here.
;;; - Duplicates are removed without inventing global ignored-path policy.
;; : (-> (List String) (List String) (List String) )
(def (workspace-scope-included-dirs source-roots runtime-roots)
  (unique-scope-dirs (append source-roots runtime-roots)))

;;; Stable path-set boundary:
;;; - Keep first occurrence order so packet fields remain deterministic.
;;; - Equality is string-based because source-scope roots are project paths.
;; unique-scope-dirs
;; : (-> (List String) (List String) )
;;   | doc m%
;;       `unique-scope-dirs` keeps the first occurrence of each source-scope
;;       directory while preserving packet order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (unique-scope-dirs '("src" "src" "t"))
;;       ;; => ("src" "t")
;;       ```
;;     %
(def (unique-scope-dirs values)
  (if (null? values)
    '()
    (cons (car values)
          (unique-scope-dirs
           (filter (lambda (value)
                     (not (equal? value (car values))))
                   (cdr values))))))

;;; Display helper boundary:
;;; - Empty lists are rendered as one dash to keep packet fields compact.
;;; - Non-empty lists preserve their configured order.
;; : (-> (List String) String )
(def (join-or-dash values)
  (if (and values (pair? values))
    (string-join values ",")
    "-"))

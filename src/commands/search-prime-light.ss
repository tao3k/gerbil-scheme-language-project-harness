;;; -*- Gerbil -*-
;;; Lightweight prime-seeds renderer for the Gerbil search command.

(import :gerbil/gambit
        :constants
        (only-in :std/misc/path directory-files path-expand path-normalize)
        (only-in :std/sort sort)
        (only-in :std/srfi/13
                 string-contains
                 string-index
                 string-index-right
                 string-join
                 string-prefix?
                 string-suffix?))

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

;; ConfigConstant
(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
;; ConfigConstant
(def +config-files+ '("gerbil.pkg" "build.ss"))
;; Boolean
(def +ignored-dirs+
  '(".devenv" ".git" ".cache" ".run" ".gerbil" "build" "dist" "target" "src/gambit" "tree-sitter"))
;; ConfigConstant
(def +boolean-flags+
  '("--json" "--code" "--names-only" "--changed" "--full" "--more"
    "--artifact"))
;; ConfigConstant
(def +value-options+
  '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"
    "--owner"
    "--iterations" "--max-total-ms" "--max-interface-ms" "--whitelist"
    "--topic" "--intent" "--role" "--level" "--rule" "--finding" "--limit"))

;;; Light package model:
;;; - Keep release launcher dependencies local to this file.
;;; - Full parser/policy modules still own deep semantic facts; prime light only
;;;   needs package identity, dependencies, and source-scope hints.
;; : (-> String (U String #f) (List String) String MaybeSourceScopePolicy ProjectPackage)
(def (make-project-package path name dependencies manager source-scope-policy)
  [path name dependencies manager source-scope-policy])

;; : (-> ProjectPackage String)
(def (project-package-path package)
  (list-ref package 0))

;; : (-> ProjectPackage (U String #f))
(def (project-package-name package)
  (list-ref package 1))

;; : (-> ProjectPackage (List String))
(def (project-package-dependencies package)
  (list-ref package 2))

;; : (-> ProjectPackage String)
(def (project-package-manager package)
  (list-ref package 3))

;; : (-> ProjectPackage MaybeSourceScopePolicy)
(def (project-package-source-scope-policy package)
  (list-ref package 4))

;; : (-> (List String) (List String) (List String) (U String #f) SourceScopePolicy)
(def (make-source-scope-policy roots runtime-roots exclude-directories explanation)
  [roots runtime-roots exclude-directories explanation])

;; : (-> SourceScopePolicy (List String))
(def (source-scope-policy-roots policy)
  (list-ref policy 0))

;; : (-> SourceScopePolicy (List String))
(def (source-scope-policy-runtime-roots policy)
  (list-ref policy 1))

;; : (-> SourceScopePolicy (List String))
(def (source-scope-policy-exclude-directories policy)
  (list-ref policy 2))

;; : (-> SourceScopePolicy (U String #f))
(def (source-scope-policy-explanation policy)
  (list-ref policy 3))

;; : (-> String ParsedData)
(def (read-project-package root)
  (let* ((package-form (read-package-form root))
         (build-scope (read-build-source-scope-policy root)))
    (cond
     (package-form
      (make-project-package "gerbil.pkg"
                            (datum->string (safe-cadr package-form))
                            (package-dependencies package-form)
                            "gxpkg"
                            (or (package-source-scope-policy package-form)
                                build-scope)))
     (build-scope
      (make-project-package "build.ss"
                            #f
                            '()
                            "gxpkg"
                            build-scope))
     (else #f))))

;; : (-> String ParsedData)
(def (read-package-form root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path)))
       (find package-form? forms)))))

;; : (-> String MaybeSourceScopePolicy)
(def (read-build-source-scope-policy root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "build.ss" root))
            (forms (read-package-forms path))
            (targets (build-script-targets forms))
            (runtime-roots (build-target-source-roots targets)))
       (and (pair? runtime-roots)
            (make-source-scope-policy
             '()
             runtime-roots
             '()
             "Inferred from build.ss defbuild-script targets."))))))

;; : (-> String (List Datum))
(def (read-package-forms path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let ((next (read port)))
          (if (eof-object? next)
            (reverse out)
            (lp (cons next out))))))))

;; : (-> Datum Boolean)
(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))

;; : (-> Datum (List String))
(def (package-dependencies datum)
  (let ((deps (package-field-value datum 'depend:)))
    (if deps
      (unique (filter-map datum->string (datum-list-items deps)))
      '())))

;; : (-> Datum MaybeSourceScopePolicy)
(def (package-source-scope-policy datum)
  (let ((policy (package-field-value datum 'policy:)))
    (and policy
         (let ((entry (policy-source-scope-entry policy)))
           (and entry
                (make-source-scope-policy
                 (or (policy-string-list-field entry 'roots:)
                     (policy-string-list-field entry 'source-roots:)
                     (policy-string-list-field entry 'source-root:)
                     '())
                 (or (policy-string-list-field entry 'runtime-roots:)
                     (policy-string-list-field entry 'runtime-root:)
                     '())
                 (or (policy-string-list-field entry 'exclude-directories:)
                     (policy-string-list-field entry 'excluded-directories:)
                     (policy-string-list-field entry 'ignore-directories:)
                     '())
                 (policy-string-field entry 'explanation:)))))))

;; : (-> Policy MaybeSourceScopeEntry)
(def (policy-source-scope-entry policy)
  (if (source-scope-policy-form? policy)
    policy
    (find source-scope-policy-form? (datum-list-items policy))))

;; : (-> Datum Boolean)
(def (source-scope-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-scope))))

;; : (-> Datum Symbol Datum)
(def (package-field-value datum field)
  (let lp ((rest (if (pair? datum) (cdr datum) '())))
    (cond
     ((null? rest) #f)
     ((and (eq? (car rest) field)
           (pair? (cdr rest)))
      (cadr rest))
     (else (lp (cdr rest))))))

;; : (-> Datum Symbol (List String))
(def (policy-string-list-field entry field)
  (let ((value (package-field-value entry field)))
    (and value (datum-string-list value))))

;; : (-> Datum Symbol (U String #f))
(def (policy-string-field entry field)
  (datum->string (package-field-value entry field)))

;; : (-> Datum (List String))
(def (datum-string-list value)
  (cond
   ((not value) #f)
   ((pair? value) (unique (filter-map datum->string (datum-list-items value))))
   (else (let ((string-value (datum->string value)))
           (if string-value [string-value] '())))))

;; : (-> (List Datum) (List String))
(def (build-script-targets forms)
  (let ((form (find build-script-form? forms)))
    (if form
      (build-script-target-value (safe-cadr form))
      '())))

;; : (-> Datum Boolean)
(def (build-script-form? datum)
  (and (pair? datum) (eq? (car datum) 'defbuild-script)))

;; : (-> Datum (List String))
(def (build-script-target-value datum)
  (cond
   ((not datum) '())
   ((quoted-datum? datum) (build-script-target-value (safe-cadr datum)))
   ((or (string? datum) (symbol? datum)) [(datum->string datum)])
   (else (filter-map datum->string (datum-list-items datum)))))

;; : (-> Datum Boolean)
(def (quoted-datum? datum)
  (and (pair? datum) (eq? (car datum) 'quote)))

;; : (-> (List String) (List String))
(def (build-target-source-roots targets)
  (unique (filter-map build-target-source-root targets)))

;; : (-> String (U String #f))
(def (build-target-source-root target)
  (let ((slash (and target (string-index target #\/))))
    (cond
     ((not target) #f)
     ((not slash) ".")
     ((fx= slash 0) ".")
     (else (substring target 0 slash)))))

;; : (-> String (List String) Boolean)
(def (flag? flag args)
  (member flag args))

;; : (-> String (List String) (U #f String))
(def (option flag args)
  (cond
   ((null? args) #f)
   ((and (pair? (cdr args)) (equal? (car args) flag))
    (cadr args))
   (else (option flag (cdr args)))))

;; : (-> (List String) (List String))
(def (positional-args args)
  (let lp ((rest args) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((member (car rest) +value-options+)
      (lp (if (pair? (cdr rest)) (cddr rest) (cdr rest)) out))
     ((or (member (car rest) +boolean-flags+)
          (string-prefix? "--" (car rest)))
      (lp (cdr rest) out))
     (else (lp (cdr rest) (cons (car rest) out))))))

;; : (-> (List String) ProjectRoot)
(def (project-root args)
  (or (option "--workspace" args)
      (let ((pos (positional-args args)))
        (if (and (pair? pos) (file-directory? (last-item pos)))
          (last-item pos)
          "."))))

;; : (-> (List String) DropProjectRoot)
(def (drop-project-root args)
  (let* ((pos (positional-args args))
         (root? (and (pair? pos) (file-directory? (last-item pos))))
         (root-index (and root? (length pos))))
    (if root?
      (drop-positional-index args root-index)
      args)))

;; : (-> (List String) Integer (List String))
(def (drop-positional-index args target-index)
  (let lp ((rest args) (out '()) (index 0))
    (cond
     ((null? rest) (reverse out))
     ((and (member (car rest) +value-options+)
           (pair? (cdr rest)))
      (lp (cddr rest) (cons (cadr rest) (cons (car rest) out)) index))
     ((member (car rest) +value-options+)
      (lp (cdr rest) (cons (car rest) out) index))
     ((or (member (car rest) +boolean-flags+)
          (string-prefix? "--" (car rest)))
      (lp (cdr rest) (cons (car rest) out) index))
     (else
      (let ((next-index (fx1+ index)))
        (if (fx= next-index target-index)
          (lp (cdr rest) out next-index)
          (lp (cdr rest) (cons (car rest) out) next-index)))))))

;; : (-> String Boolean)
(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> Root Integer ProjectPackage (List Path))
(def (collect-source-files-preview root limit package)
  (let* ((scope-policy (and package
                            (project-package-source-scope-policy package)))
         (source-roots (workspace-source-roots scope-policy))
         (ignored-dirs (append +ignored-dirs+
                               (workspace-exclude-directories scope-policy)))
         (configs (take-up-to (root-config-files root) limit))
         (remaining (- limit (length configs))))
    (unique
     (map path-normalize
          (append configs
                  (if (> remaining 0)
                    (scan-source-files-preview root source-roots ignored-dirs remaining)
                    '()))))))

;; : (-> Root (List Path))
(def (root-config-files root)
  (filter-list
   (lambda (path)
     (file-exists? (path-expand path root)))
   (map (lambda (path) (path-expand path root))
        +config-files+)))

;; : (-> Root (List String) (List String) Integer (List Path))
(def (scan-source-files-preview root scan-roots ignored-dirs limit)
  (let ((result '())
        (remaining limit))
    (def (add-file path)
      (when (> remaining 0)
        (set! result (cons path result))
        (set! remaining (- remaining 1))))
    (def (walk dir)
      (when (> remaining 0)
        (for-each
         (lambda (entry)
           (when (> remaining 0)
             (unless (member entry '("." ".."))
               (let ((path (path-expand entry dir)))
                 (cond
                  ((and (source-directory? path)
                        (not (ignored-source-directory? root path entry ignored-dirs)))
                   (walk path))
                  ((gerbil-source-path? path)
                   (add-file path))
                  (else #!void))))))
         (sort (directory-files dir) string<?))))
    (for-each
     (lambda (source-root)
       (when (> remaining 0)
         (let ((path (path-expand source-root root)))
           (when (source-directory? path)
             (walk path)))))
     scan-roots)
    (reverse result)))

;; : (-> String Boolean)
(def (source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> Root Path String (List String) Boolean)
(def (ignored-source-directory? root path entry ignored-dirs)
  (or (member entry ignored-dirs)
      (member (relative-owner-path root path) ignored-dirs)))

;; : (-> Path Boolean)
(def (gerbil-source-path? path)
  (any (lambda (extension)
         (string-suffix? extension path))
       +source-extensions+))

;; : (-> SourcePath SourceClass)
(def (source-path-class path)
  (cond
   ((equal? path "gerbil.pkg")
    "config")
   ((equal? path "build.ss")
    "package-build")
   ((and (string-prefix? "build-support/" path)
         (string-suffix? ".ss" path))
    "build-support-runtime")
   ((or (string-prefix? "t/snapshots/" path)
        (string-contains path "/snapshots/"))
    "snapshot-output")
   ((or (string-prefix? "t/scenarios/" path)
        (string-contains path "/scenarios/"))
    "policy-scenario")
   ((or (string-prefix? "t/fixtures/" path)
        (string-contains path "/fixtures/"))
    "fixture")
   ((or (string-prefix? "t/" path)
        (string-contains path "/t/"))
    "test")
   ((or (string-contains path "/generated/")
        (string-contains path ".generated."))
    "generated")
   ((or (string-prefix? "src/check-fast/" path)
        (equal? path "src/search-fast/gerbil-scheme-search-extension.ss")
        (equal? path "src/search-fast/gerbil-scheme-search-pattern.ss"))
    "native-fast-runtime")
   ((or (string-prefix? "src/" path)
        (string-prefix? "bin/" path))
    "runtime-source")
   (else "source")))

;; : (-> (List a) Integer (List a))
(def (take-up-to values limit)
  (let lp ((rest values) (remaining limit) (out '()))
    (if (or (null? rest) (<= remaining 0))
      (reverse out)
      (lp (cdr rest) (- remaining 1) (cons (car rest) out)))))

;; : (-> (List a) a)
(def (last-item values)
  (if (and (pair? values) (pair? (cdr values)))
    (last-item (cdr values))
    (car values)))

;; : (-> Obj (List Obj))
(def (datum-list-items obj)
  (let ((rest obj)
        (out '()))
    (while (pair? rest)
      (set! out (cons (car rest) out))
      (set! rest (cdr rest)))
    (reverse out)))

;; : (-> Obj (U #f Obj))
(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

;; : (-> Obj (U #f String))
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   ((keyword? obj) (string-append (keyword->string obj) ":"))
   (else (call-with-output-string "" (cut display obj <>)))))

;; : (-> (-> a Boolean) (List a) (U #f a))
(def (find predicate values)
  (cond
   ((null? values) #f)
   ((predicate (car values)) (car values))
   (else (find predicate (cdr values)))))

;; : (-> (-> a (U #f b)) (List a) (List b))
(def (filter-map procedure values)
  (let lp ((rest values) (out '()))
    (cond
     ((null? rest) (reverse out))
     (else
      (let ((value (procedure (car rest))))
        (lp (cdr rest) (if value (cons value out) out)))))))

;; : (-> (-> a Boolean) (List a) (List a))
(def (filter-list predicate values)
  (let lp ((rest values) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((predicate (car rest)) (lp (cdr rest) (cons (car rest) out)))
     (else (lp (cdr rest) out)))))

;; : (-> (-> a Boolean) (List a) Boolean)
(def (any predicate values)
  (and (pair? values)
       (or (predicate (car values))
           (any predicate (cdr values)))))

;; : (-> (List String) (List String))
(def (unique values)
  (let lp ((rest values) (seen '()) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((member (car rest) seen)
      (lp (cdr rest) seen out))
     (else
      (lp (cdr rest) (cons (car rest) seen) (cons (car rest) out))))))

;;; Boundary:
;;; - This command path is intentionally package/source-scope only.
;;; - ASP owns dependency source indexing, route topology, symbol indexes, and
;;;   reasoning-tree state built from this provider-owned workspace map.
;; : (-> Args Integer )
(def (search-prime-light-main args)
  (if (and (pair? args) (equal? (car args) "prime"))
    (let ((tail (cdr args)))
      (let ((root (path-normalize (project-root tail))))
        (let ((normalized-args (drop-project-root tail)))
          (let ((json? (flag? "--json" normalized-args)))
            (if json?
              (error "search prime light does not render json")
              (emit-prime-light root))))))
    (error "search-prime-light requires prime view")))

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

;;; Boundary:
;;; - The seed packet exposes durable navigation facts only.
;;; - It must not parse source forms or produce graph-derived rank.
;; : (-> Root Integer )
(def (emit-prime-light root)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (source-files-light root package)))
    (displayln "[gerbil-search-prime] root=" root
               " filePreview=" (length files)
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
       (let ((owner (relative-owner-path root path)))
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
             (files (workspace-scope-preview-files-light root package)))
        (emit-workspace-scope-lines-light root package files)
        0)))

;; : (-> Root MaybePackage (List Path) Unit )
(def (emit-workspace-scope-lines-light root package files)
  (let* ((policy (and package
                      (project-package-source-scope-policy package)))
         (source-roots (workspace-source-roots policy))
         (runtime-roots (workspace-runtime-roots policy))
         (exclude-directories (workspace-exclude-directories policy))
         (status (if package "ready" "missing-anchor")))
    (displayln "[gerbil-workspace-scope] root=" root
               " status=" status
               " filePreview=" (length files)
               " scopeOwner=" +provider-id+
               " indexOwner=asp-rust-sql-source-index")
    (displayln "|anchor path=" (if package (project-package-path package) "missing")
               " packageManager=" (if package (project-package-manager package) "gxpkg")
               " packageName=" (or (and package (project-package-name package)) "-"))
    (displayln "|coverage configFiles=" (join-or-dash +config-files+)
               " sourceExtensions=" (join-or-dash +source-extensions+)
               " sourceRoots=" (join-or-dash source-roots)
               " runtimeRoots=" (join-or-dash runtime-roots)
               " ignoredPathPrefixes=" (join-or-dash (append +ignored-dirs+
                                                              exclude-directories)))
    (for-each
     (lambda (path)
       (let* ((owner (relative-owner-path root path))
              (source-class (source-path-class owner)))
         (displayln "|file path=" owner
                    " sourceClass=" source-class
                    " sourceKind=" (if (equal? source-class "config")
                                      "config"
                                      "source"))))
     (take-up-to files 24))
    (displayln "nextCommand=asp cache source-index refresh")))

;; : (-> Root MaybePackage (List Path) )
(def (source-files-light root package)
  (if package
    (collect-source-files-preview root +prime-light-preview-limit+ package)
    '()))

;; : (-> Root MaybePackage (List Path) )
(def (workspace-scope-preview-files-light root package)
  (if package
    (map (lambda (path)
           (path-normalize (path-expand path root)))
         +config-files+)
    '()))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-source-roots policy)
  (let ((roots (and policy (source-scope-policy-roots policy))))
    (if (and roots (pair? roots)) roots ["."])))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-runtime-roots policy)
  (let ((roots (and policy (source-scope-policy-runtime-roots policy))))
    (if roots roots '())))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-exclude-directories policy)
  (let ((dirs (and policy (source-scope-policy-exclude-directories policy))))
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
  (let ((last-path-char
         (string-index-right path
                             (lambda (char)
                               (not (char=? char #\/))))))
    (if (and last-path-char
             (< (fx1+ last-path-char) (string-length path)))
      (substring path 0 (fx1+ last-path-char))
      path)))

;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns the search command dispatcher and compact owner views.
;;; - Evidence packet rendering lives in :commands/search-evidence.
;;; Search command adapter.

(import :constants
        :commands/guide
        :commands/search-evidence
        :commands/search-extension
        :commands/search-owner-items
        (only-in :commands/search-prime-light
                 emit-prime-light
                 source-path-class)
        :commands/search-proof
        :commands/search-structural
        :commands/search-workspace-scope
        :extensions/facade
        :parser/facade
        :parser/query
        :protocol/json
        :support/args
        :support/io
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13 string-contains string-join)
        (only-in :std/sugar cut filter match ormap))

(export search-main
        language-evidence-view?
        language-evidence-index-free-view?
        language-evidence-authority
        language-evidence-next)
;; search-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `search-main args` dispatches a search view and returns a process-style
;;       status code for the harness CLI.
;;
;;       # Examples
;;
;;       ```scheme
;;       (search-main '("prime" "--workspace" "."))
;;       ;; => 0
;;       ```
;;     %
(def (search-main args)
  (match args
    ([] (error "search requires a view"))
    ([view . rest]
     (if (equal? view "guide")
       (begin (print-guide) 0)
       (let* ((root (project-root rest))
              (args (drop-project-root rest))
              (json? (flag? "--json" args)))
         (cond
          ((equal? view "compare") (emit-compare-search args json?))
          ((equal? view "proof") (emit-type-proof-search args json?))
          ((language-evidence-index-free-view? view)
           (emit-language-evidence-search root view args json?))
          ((poo-pattern-package-only-search? view args)
           (emit-pattern-search
            (collect-project-package-only root)
            args
            json?))
          ((equal? view "workspace-scope")
           (emit-workspace-scope root json?))
          ((and (equal? view "prime")
                (prime-seeds-view? args)
                (not json?))
           (emit-prime-light root))
          ((equal? view "extension")
           (emit-extension-search
            (collect-project-package-only root)
            args
            json?))
          (else
           (let (index (if (equal? view "owner")
                         (owner-search-index root args)
                         (collect-project root)))
             (cond
              ((equal? view "workspace") (emit-workspace index json?))
              ((equal? view "prime") (emit-prime index json?))
              ((equal? view "owner") (emit-owner-search index args json?))
              ((equal? view "symbol") (emit-symbol-search index args json?))
              ((equal? view "import") (emit-import-search index args json?))
              ((equal? view "structural")
               (emit-structural-index index args json?))
              ((equal? view "extension") (emit-extension-search index args json?))
              ((equal? view "pattern") (emit-pattern-search index args json?))
              ((equal? view "compare") (emit-compare-search args json?))
              ((equal? view "proof") (emit-type-proof-search args json?))
              ((language-evidence-view? view)
               (emit-language-evidence-search index view args json?))
              ((or (equal? view "fzf") (equal? view "pipe"))
               (emit-fzf-search index args json?))
              ((equal? view "ingest") (emit-ingest index json?))
              (else (error "unsupported search view" view)))))))))))
;; : (-> String (List String) ProjectIndex )
(def (owner-search-index root args)
  (if (explicit-owner-search-path? root args)
    (collect-project-package-only root)
    (collect-project root)))

;; : (-> String (List String) Boolean )
(def (explicit-owner-search-path? root args)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals)))
         (path (and owner (path-expand owner (path-normalize root)))))
    (and path
         (gerbil-source-path? path)
         (file-exists? path))))

;; : (-> SearchView Args Boolean )
(def (poo-pattern-package-only-search? view args)
  (and (equal? view "pattern")
       (poo-pattern-query? (positional-args args))))

;; : (-> Args Boolean )
(def (prime-seeds-view? args)
  (or (equal? (option "--view" args) "seeds")
      (member "seeds" args)))
;; emit-workspace
;;   : (-> ProjectIndex Boolean Integer)
;;   | doc m%
;;       `emit-workspace index json?` emits workspace owners and package
;;       metadata as JSON or compact human-readable lines.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-workspace index #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-workspace index json?)
  (if json?
    (write-json-line
     (hash (languageId +language-id+)
           (providerId +provider-id+)
           (root (project-index-root index))
           (projectPackage (project-package-json (project-index-package index)))
           (extensions (project-extension-json index))
           (files (map source-file-json (project-index-files index)))))
    (begin
      (displayln "[gerbil-workspace] root=" (project-index-root index)
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index)))
      (emit-package-line index)
      (emit-extension-lines index)
      (for-each
        (lambda (file)
          (displayln "|owner path=" (source-file-path file)
                     " package=" (or (source-file-package file) "-")
                     " defs=" (length (source-file-definitions file))))
        (let (files (project-index-files index))
          (take files (min 20 (length files)))))))
  0)
;; emit-prime
;;   : (-> ProjectIndex Boolean Integer)
;;   | doc m%
;;       `emit-prime index json?` emits the prime search packet or the compact
;;       seed view for the current project.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-prime index #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-prime index json?)
  (if json?
    (write-json-line
     (search-prime-packet-json index))
    (begin
      (displayln "[gerbil-search-prime] root=" (project-index-root index)
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index)))
      (displayln "|language id=" +language-id+ " provider=" +provider-id+
                 " parser=core-read-module")
      (emit-package-line index)
      (emit-extension-lines index)
      (for-each
       (lambda (file)
         (displayln "owner:path(" (source-file-path file) ")"
                    " package=" (or (source-file-package file) "-")
                    " sourceClass=" (source-path-class (source-file-path file))
                    " defs=" (length (source-file-definitions file))
                    " imports=" (length (source-file-imports file))))
       (let (files (ranked-files index))
         (take files (min 12 (length files)))))
      (displayln "recommendedNext=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")
      (displayln "nextCommand=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")))
  0)

;; : (-> ProjectIndex String )
(def (emit-package-line index)
  (let (package (project-index-package index))
    (when package
      (displayln "|package name=" (project-package-name package)
                 " path=" (project-package-path package)
                 " packageManager=" (project-package-manager package)
                 " dependencies=" (string-join (project-package-dependencies package) ",")))))
;; : (-> ProjectIndex (List String) )
(def (emit-extension-lines index)
  (for-each displayln (project-extension-search-lines index)))
;;; Boundary:
;;; - resolve-owner-file owns owner path fallback semantics.
;;; - Keep indexed owners first; parse explicit files only when they are Gerbil sources.
;; : (-> ProjectIndex String SourceFile )
(def (resolve-owner-file index owner)
  (or (find-owner index owner)
      (resolve-explicit-owner-file index owner)))
;; : (-> ProjectIndex String MaybeSourceFile )
(def (resolve-explicit-owner-file index owner)
  (let* ((root (project-index-root index))
         (path (path-expand owner root)))
    (and (gerbil-source-path? path)
         (file-exists? path)
         (parse-source-file root path))))
;; emit-owner-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-owner-search index args json?` resolves an owner path and emits
;;       either owner details, owner item matches, or owner JSON.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-owner-search index '("src/parser/support.ss") #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-owner-search index args json?)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals))))
    (unless owner (error "search owner requires a path"))
    (let (file (resolve-owner-file index owner))
      (unless file (error "owner not found" owner))
      (if (and (pair? (cdr positionals)) (equal? (cadr positionals) "items"))
        (let* ((query (option "--query" args))
               (terms (owner-item-query-terms query))
               (limit (owner-items-limit args))
               (definition-matches
                (matching-definitions (source-file-definitions file) terms))
               (syntax-limit (max 0 (- limit (length definition-matches))))
               (syntax-matches (matching-owner-syntax-facts file terms syntax-limit)))
          (cond
           ((flag? "--code" args)
            (for-each (lambda (defn)
                        (display (read-definition-code (project-index-root index) defn)))
                      definition-matches))
           ((flag? "--names-only" args)
            (for-each (lambda (defn) (displayln (definition-name defn)))
                      (take definition-matches
                            (min limit (length definition-matches))))
            (for-each (lambda (fact) (displayln (hash-get fact 'name)))
                      syntax-matches))
           (else (emit-owner-items file definition-matches syntax-matches limit))))
        (if json?
          (write-json-line (source-file-json file))
          (emit-owner file))))
    0))

;; : (-> Args Integer )
(def (owner-items-limit args)
  (let* ((value (option "--limit" args))
         (parsed (and value (string->number value))))
    (cond
     ((not value) 80)
     ((and (integer? parsed) (>= parsed 0)) parsed)
     (else (error "invalid owner-items --limit" value)))))
;; emit-owner
;;   : (-> SourceFile Unit)
;;   | doc m%
;;       `emit-owner file` prints compact owner metadata, imports, definitions,
;;       and the next command hint for a source file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-owner file)
;;       ;; => (void)
;;       ```
;;     %
(def (emit-owner file)
  (displayln "[gerbil-owner] path=" (source-file-path file)
             " package=" (or (source-file-package file) "-")
             " sourceClass=" (source-path-class (source-file-path file))
             " defs=" (length (source-file-definitions file))
             " imports=" (length (source-file-imports file))
             " exports=" (length (source-file-exports file)))
  (when (source-file-prelude file)
    (displayln "|prelude " (source-file-prelude file)))
  (when (source-file-namespace file)
    (displayln "|namespace " (source-file-namespace file)))
  (unless (null? (source-file-imports file))
    (displayln "|imports " (string-join (source-file-imports file) ",")))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   (let (definitions (source-file-definitions file))
     (take definitions (min 30 (length definitions)))))
  (displayln "nextCommand=gerbil-scheme-harness query " (source-file-path file)
             " --term '<symbol>' --workspace . --names-only"))
;; emit-symbol-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-symbol-search index args json?` searches indexed definitions by
;;       symbol query and emits JSON or compact match rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-symbol-search index '("datum-list-items") #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-symbol-search index args json?)
  (let* ((positionals (positional-args args))
         (query (and (pair? positionals) (car positionals))))
    (unless query (error "search symbol requires a query"))
    (let (matches (matching-definitions (project-definitions index) [query]))
      (if json?
        (write-json-line (hash (query query) (matches (map definition-json matches))))
        (begin
          (displayln "[gerbil-search-symbol] query=" query
                     " matches=" (length matches))
          (for-each
           (lambda (defn)
             (displayln "|match name=" (definition-name defn)
                        " kind=" (definition-kind defn)
                        " selector=" (definition-selector defn)))
           (take matches (min 40 (length matches)))))))
    0))
;; emit-import-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-import-search index args json?` searches source imports and
;;       includes for the query term and emits matching owners.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-import-search index '(":parser/support") #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-import-search index args json?)
  (let* ((positionals (positional-args args))
         (query (and (pair? positionals) (car positionals))))
    (unless query (error "search import requires a query"))
    (let (matches
          (filter
           (lambda (file)
             (ormap (cut string-contains <> query)
                    (append (source-file-imports file) (source-file-includes file))))
           (project-index-files index)))
      (if json?
        (write-json-line (hash (query query) (matches (map source-file-json matches))))
        (begin
          (displayln "[gerbil-search-import] query=" query " owners=" (length matches))
          (for-each
           (lambda (file)
             (displayln "|owner path=" (source-file-path file)))
           (take matches (min 40 (length matches)))))))
    0))
;; emit-fzf-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-fzf-search index args json?` ranks owners for a fuzzy query and
;;       emits JSON or compact owner rows with a follow-up command.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-fzf-search index '("typed doc") #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-fzf-search index args json?)
  (let* ((positionals (positional-args args))
         (query (and (pair? positionals) (car positionals))))
    (unless query (error "search fzf requires a query"))
    (let (matches (ranked-query-files index query))
      (if json?
        (write-json-line (hash (query query) (matches (map source-file-json matches))))
        (begin
          (displayln "[gerbil-search-fzf] query=" query " matches=" (length matches))
          (for-each
           (lambda (file)
             (displayln "|owner path=" (source-file-path file)
                        " package=" (or (source-file-package file) "-")
                        " sourceClass=" (source-path-class (source-file-path file))
                        " defs=" (length (source-file-definitions file))))
           (take matches (min 24 (length matches))))
          (when (pair? matches)
            (displayln "recommendedNext=gerbil-scheme-harness search owner "
                       (source-file-path (car matches)) " --workspace . --view seeds")))))
    0))

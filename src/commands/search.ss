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
        :commands/search-structural
        :commands/search-workspace-scope
        :extensions/facade
        :parser/facade
        :parser/query
        :protocol/json
        :support/args
        :support/io
        :support/list
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter match ormap))

(export search-main
        language-evidence-view?
        language-evidence-index-free-view?
        language-evidence-authority
        language-evidence-next)
;;; Invariant:
;;; - search-main owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; SearchMain <- (List XX)
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
          ((language-evidence-index-free-view? view)
           (emit-language-evidence-search #f view args json?))
          ((poo-pattern-package-only-search? view args)
           (emit-pattern-search
            (collect-project-package-only root)
            args
            json?))
          ((equal? view "workspace-scope")
           (emit-workspace-scope root json?))
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
              ((language-evidence-view? view)
               (emit-language-evidence-search index view args json?))
              ((or (equal? view "fzf") (equal? view "pipe"))
               (emit-fzf-search index args json?))
              ((equal? view "ingest") (emit-ingest index json?))
              (else (error "unsupported search view" view)))))))))))
;; ProjectIndex <- String (List String)
(def (owner-search-index root args)
  (if (explicit-owner-search-path? root args)
    (collect-project-package-only root)
    (collect-project root)))

;; Boolean <- String (List String)
(def (explicit-owner-search-path? root args)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals)))
         (path (and owner (path-expand owner (path-normalize root)))))
    (and path
         (gerbil-source-path? path)
         (file-exists? path))))

;; Boolean <- SearchView Args
(def (poo-pattern-package-only-search? view args)
  (and (equal? view "pattern")
       (poo-pattern-query? (positional-args args))))
;;; Boundary:
;;; - emit-workspace composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex Json
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
        (take* (project-index-files index) 20))))
  0)
;;; Boundary:
;;; - emit-prime composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex Json
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
       (take* (ranked-files index) 12))
      (displayln "recommendedNext=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")
      (displayln "nextCommand=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")))
  0)
;; String <- ProjectIndex
(def (emit-package-line index)
  (let (package (project-index-package index))
    (when package
      (displayln "|package name=" (project-package-name package)
                 " path=" (project-package-path package)
                 " packageManager=" (project-package-manager package)
                 " dependencies=" (join (project-package-dependencies package) ",")))))
;; (List String) <- ProjectIndex
(def (emit-extension-lines index)
  (for-each displayln (project-extension-search-lines index)))
;;; Boundary:
;;; - resolve-owner-file owns owner path fallback semantics.
;;; - Keep indexed owners first; parse explicit files only when they are Gerbil sources.
;; SourceFile <- ProjectIndex String
(def (resolve-owner-file index owner)
  (or (find-owner index owner)
      (resolve-explicit-owner-file index owner)))
;; MaybeSourceFile <- ProjectIndex String
(def (resolve-explicit-owner-file index owner)
  (let* ((root (project-index-root index))
         (path (path-expand owner root)))
    (and (gerbil-source-path? path)
         (file-exists? path)
         (parse-source-file root path))))
;;; Boundary:
;;; - emit-owner-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List String) Json
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
                      (take* definition-matches limit))
            (for-each (lambda (fact) (displayln (hash-get fact 'name)))
                      syntax-matches))
           (else (emit-owner-items file definition-matches syntax-matches limit))))
        (if json?
          (write-json-line (source-file-json file))
          (emit-owner file))))
    0))

;; Integer <- Args
(def (owner-items-limit args)
  (let* ((value (option "--limit" args))
         (parsed (and value (string->number value))))
    (cond
     ((not value) 80)
     ((and (integer? parsed) (>= parsed 0)) parsed)
     (else (error "invalid owner-items --limit" value)))))
;;; Boundary:
;;; - emit-owner composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- SourceFile
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
    (displayln "|imports " (join (source-file-imports file) ",")))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   (take* (source-file-definitions file) 30))
  (displayln "nextCommand=gerbil-scheme-harness query " (source-file-path file)
             " --term '<symbol>' --workspace . --names-only"))
;;; Boundary:
;;; - emit-symbol-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List String) Json
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
           (take* matches 40)))))
    0))
;;; Boundary:
;;; - emit-import-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List XX) Json
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
           (take* matches 40)))))
    0))
;;; Boundary:
;;; - emit-fzf-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List XX) Json
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
           (take* matches 24))
          (when (pair? matches)
            (displayln "recommendedNext=gerbil-scheme-harness search owner "
                       (source-file-path (car matches)) " --workspace . --view seeds")))))
    0))

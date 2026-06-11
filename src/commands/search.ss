;;; -*- Gerbil -*-
;;; Search command adapter.

(import :constants
        :parser
        :parser/query
        :protocol/json
        :support/args
        :support/io
        :support/list
        :std/misc/ports
        :std/srfi/13)

(export search-main)

(def (search-main args)
  (match args
    ([] (error "search requires a view"))
    ([view . rest]
     (let* ((root (project-root rest))
            (args (drop-project-root rest))
            (index (collect-project root))
            (json? (flag? "--json" args)))
       (cond
        ((equal? view "workspace") (emit-workspace index json?))
        ((equal? view "prime") (emit-prime index json?))
        ((equal? view "owner") (emit-owner-search index args json?))
        ((equal? view "symbol") (emit-symbol-search index args json?))
        ((equal? view "import") (emit-import-search index args json?))
        ((equal? view "fzf") (emit-fzf-search index args json?))
        ((equal? view "ingest") (emit-ingest index json?))
        (else (error "unsupported search view" view)))))))

(def (emit-workspace index json?)
  (if json?
    (write-json-line
     (hash (languageId +language-id+)
           (providerId +provider-id+)
           (root (project-index-root index))
           (files (map source-file-json (project-index-files index)))))
    (begin
      (displayln "[gerbil-workspace] root=" (project-index-root index)
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index)))
      (for-each
        (lambda (file)
          (displayln "|owner path=" (source-file-path file)
                     " package=" (or (source-file-package file) "-")
                     " defs=" (length (source-file-definitions file))))
        (take* (project-index-files index) 20))))
  0)

(def (emit-prime index json?)
  (if json?
    (write-json-line
     (hash (schemaId "agent.semantic-protocols.semantic-search-packet")
           (schemaVersion "1")
           (languageId +language-id+)
           (providerId +provider-id+)
           (view "prime")
           (root (project-index-root index))
           (owners (map source-file-json (take* (ranked-files index) 100)))))
    (begin
      (displayln "[gerbil-search-prime] root=" (project-index-root index)
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index)))
      (displayln "|language id=" +language-id+ " provider=" +provider-id+
                 " parser=core-read-module")
      (for-each
       (lambda (file)
         (displayln "owner:path(" (source-file-path file) ")"
                    " package=" (or (source-file-package file) "-")
                    " defs=" (length (source-file-definitions file))
                    " imports=" (length (source-file-imports file))))
       (take* (ranked-files index) 12))
      (displayln "recommendedNext=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")
      (displayln "nextCommand=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")))
  0)

(def (emit-owner-search index args json?)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals))))
    (unless owner (error "search owner requires a path"))
    (let (file (find-owner index owner))
      (unless file (error "owner not found" owner))
      (if (and (pair? (cdr positionals)) (equal? (cadr positionals) "items"))
        (let* ((query (option "--query" args))
               (matches (matching-definitions (source-file-definitions file)
                                              (if query [query] '()))))
          (cond
           ((flag? "--code" args)
            (for-each (lambda (defn)
                        (display (read-definition-code (project-index-root index) defn)))
                      matches))
           ((flag? "--names-only" args)
            (for-each (lambda (defn) (displayln (definition-name defn))) matches))
           (else (emit-owner-items file matches))))
        (if json?
          (write-json-line (source-file-json file))
          (emit-owner file))))
    0))

(def (emit-owner file)
  (displayln "[gerbil-owner] path=" (source-file-path file)
             " package=" (or (source-file-package file) "-")
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

(def (emit-owner-items file matches)
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (length matches))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   matches))

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
                        " defs=" (length (source-file-definitions file))))
           (take* matches 24))
          (when (pair? matches)
            (displayln "recommendedNext=gerbil-scheme-harness search owner "
                       (source-file-path (car matches)) " --view seeds .")))))
    0))

(def (emit-ingest index json?)
  (let* ((stdin-text (read-all-as-string (current-input-port)))
         (matches (filter (lambda (file)
                            (string-contains stdin-text (source-file-path file)))
                          (project-index-files index))))
    (if json?
      (write-json-line (hash (owners (map source-file-json matches))))
      (begin
        (displayln "[gerbil-search-ingest] owners=" (length matches))
        (for-each (lambda (file)
                    (displayln "|owner path=" (source-file-path file)))
                  matches)))
    0))

;;; -*- Gerbil -*-
;;; Gerbil Scheme semantic project harness.

(import :gerbil/expander
        :gerbil/gambit
        :gerbil-scheme-language-project-harness/parser
        :std/format
        :std/iter
        :std/misc/ports
        :std/sort
        :std/srfi/13
        :std/text/json)
(export main)

(def +language-id+ "gerbil-scheme")
(def +provider-id+ "gerbil-scheme-harness")
(def +display-name+ "Gerbil Scheme Harness")

(def +help+
  "gerbil-scheme-harness - Gerbil Scheme semantic search and project harness

Usage:
  gerbil-scheme-harness search <view> ... [--json] [--code] [PROJECT_ROOT]
  gerbil-scheme-harness query <owner-path> --term <symbol> [--term <symbol>] [--workspace PROJECT_ROOT] [--names-only | --code]
  gerbil-scheme-harness query --from-hook direct-source-read --selector <workspace-path:start-end> --workspace PROJECT_ROOT --code
  gerbil-scheme-harness check [--changed | --full] [--json] [PROJECT_ROOT]
  gerbil-scheme-harness agent doctor [--json] [PROJECT_ROOT]
  gerbil-scheme-harness agent guide [PROJECT_ROOT]
")

(def (main . args)
  (match args
    ([] (display +help+) 0)
    (["-h"] (display +help+) 0)
    (["--help"] (display +help+) 0)
    (["help"] (display +help+) 0)
    (["search" . rest] (search-main rest))
    (["query" . rest] (query-main rest))
    (["check" . rest] (check-main rest))
    (["agent" . rest] (agent-main rest))
    (["guide" . _] (print-guide) 0)
    (else
     (display +help+)
     2)))

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

(def (query-main args)
  (let* ((workspace (or (option "--workspace" args) (project-root args)))
         (json? (flag? "--json" args))
         (code? (flag? "--code" args))
         (names-only? (flag? "--names-only" args))
         (selector (option "--selector" args))
         (from-hook (option "--from-hook" args)))
    (if (and from-hook (equal? from-hook "direct-source-read"))
      (begin
        (unless selector (error "direct-source-read requires --selector"))
        (let (code (read-selector workspace selector))
          (if json?
            (write-json-line (hash (selector selector) (code code)))
            (display code)))
        0)
      (let* ((positionals (positional-args (drop-project-root args)))
             (owner (and (pair? positionals) (car positionals)))
             (terms (options "--term" args)))
        (unless owner (error "query requires an owner path"))
        (let* ((index (collect-project workspace))
               (file (find-owner index owner)))
          (unless file (error "owner not found" owner))
          (let (matches (matching-definitions (source-file-definitions file) terms))
            (cond
             (json?
              (write-json-line (hash (owner (source-file-path file))
                                     (matches (map definition-json matches)))))
             (code?
              (for-each (lambda (defn)
                          (display (read-definition-code workspace defn)))
                        matches))
             (names-only?
              (for-each (lambda (defn) (displayln (definition-name defn))) matches))
             (else
              (emit-owner-items file matches))))
          0)))))

(def (check-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (index (collect-project root))
         (errors (filter source-file-parse-error (project-index-files index)))
         (status (if (null? errors) "pass" "fail")))
    (if json?
      (write-json-line
       (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-report")
             (schemaVersion "1")
             (languageId +language-id+)
             (providerId +provider-id+)
             (status status)
             (files (length (project-index-files index)))
             (definitions (length (project-definitions index)))
             (findings (map parse-error-json errors))))
      (begin
        (displayln "[gerbil-check] status=" status
                   " files=" (length (project-index-files index))
                   " definitions=" (length (project-definitions index))
                   " findings=" (length errors))
        (for-each
          (lambda (file)
            (displayln "|finding rule=GERBIL-SCHEME-READ-R001 path="
                       (source-file-path file)
                       " message=" (source-file-parse-error file)))
          errors)))
    (if (null? errors) 0 1)))

(def (agent-main args)
  (match args
    (["doctor" . rest]
     (let ((root (project-root rest))
           (json? (flag? "--json" rest)))
       (if json?
         (write-json-line (language-registry root))
         (displayln "[gerbil-agent-doctor] status=ok language=" +language-id+
                    " provider=" +provider-id+))
       0))
    (["guide" . _]
     (print-guide)
     0)
    (else (error "agent requires doctor or guide"))))

(def (matching-definitions definitions terms)
  (if (null? terms)
    definitions
    (filter
     (lambda (defn)
       (ormap (lambda (term)
                (string-contains (string-downcase (definition-name defn))
                                 (string-downcase term)))
              terms))
     definitions)))

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

(def (ranked-files index)
  (sort (project-index-files index)
        (lambda (a b)
          (> (length (source-file-definitions a))
             (length (source-file-definitions b))))))

(def (ranked-query-files index query)
  (filter
   (lambda (file)
     (let (haystack
           (string-append (source-file-path file) " "
                          (or (source-file-package file) "") " "
                          (join (source-file-imports file) " ") " "
                          (join (map definition-name (source-file-definitions file)) " ")))
       (string-contains (string-downcase haystack) (string-downcase query))))
   (ranked-files index)))

(def (read-definition-code root defn)
  (read-line-range (path-expand (definition-path defn) root)
                   (definition-start defn)
                   (definition-end defn)))

(def (read-selector root selector)
  (let* ((parts (split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts)))
    (read-line-range (path-expand path root) start end)))

(def (split-selector selector)
  (let* ((ix (string-index-right selector #\:))
         (path (substring selector 0 ix))
         (range (substring selector (fx1+ ix) (string-length selector)))
         (dash (string-index range #\-)))
    (if dash
      [path
       (string->number (substring range 0 dash))
       (string->number (substring range (fx1+ dash) (string-length range)))]
      [path (string->number range) (string->number range)])))

(def (read-line-range path start end)
  (let (lines (read-file-lines path))
    (let lp ((rest lines) (line 1) (out ""))
      (cond
       ((null? rest) out)
       ((> line end) out)
       ((>= line start)
        (lp (cdr rest) (fx1+ line) (string-append out (car rest) "\n")))
       (else
        (lp (cdr rest) (fx1+ line) out))))))

(def (source-file-json file)
  (hash (path (source-file-path file))
        (package (source-file-package file))
        (prelude (source-file-prelude file))
        (namespace (source-file-namespace file))
        (imports (source-file-imports file))
        (exports (source-file-exports file))
        (includes (source-file-includes file))
        (definitions (map definition-json (source-file-definitions file)))
        (forms (map top-form-json (source-file-forms file)))
        (parseError (source-file-parse-error file))))

(def (definition-json defn)
  (hash (name (definition-name defn))
        (kind (definition-kind defn))
        (path (definition-path defn))
        (start (definition-start defn))
        (end (definition-end defn))
        (selector (definition-selector defn))))

(def (top-form-json form)
  (hash (kind (top-form-kind form))
        (head (top-form-head form))
        (path (top-form-path form))
        (start (top-form-start form))
        (end (top-form-end form))
        (selector (top-form-selector form))))

(def (parse-error-json file)
  (hash (path (source-file-path file))
        (ruleId "GERBIL-SCHEME-READ-R001")
        (message (source-file-parse-error file))))

(def (language-registry root)
  (hash
   (registryId "agent.semantic-protocols.semantic-language-registry")
   (registryVersion "1")
   (protocolId "agent.semantic-protocols.semantic-language")
   (protocolVersion "1")
   (languages
    [(hash
      (languageId +language-id+)
      (providerId +provider-id+)
      (binary "gerbil-scheme-harness")
      (execution "external-process")
      (namespace "agent.semantic-protocols.languages.gerbil-scheme.gerbil-scheme-harness")
      (displayName +display-name+)
      (packageRoots [root])
      (methods ["search/prime" "search/owner" "search/fzf" "search/ingest"
                "query/direct-source-read" "check/changed" "guide"])
      (source (hash
               (defaultExtensions +source-extensions+)
               (defaultConfigFiles +config-files+)
               (defaultSourceRoots ["src" "test" "tests" "doc" "docs" "examples" "tutorial"])
               (defaultIgnoredPathPrefixes +ignored-dirs+))))])))

(def (print-guide)
  (displayln "gerbil-scheme-harness guide")
  (displayln "|cmd prime=gerbil-scheme-harness search prime --view seeds .")
  (displayln "|cmd fzf=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")
  (displayln "|cmd owner=gerbil-scheme-harness search owner <path> --view seeds .")
  (displayln "|cmd owner-items=gerbil-scheme-harness search owner <path> items --query <symbol> --names-only .")
  (displayln "|cmd query-code=gerbil-scheme-harness query <path> --term <symbol> --workspace . --code")
  (displayln "|cmd check=gerbil-scheme-harness check --changed ."))

(def (write-json-line obj)
  (write-json obj)
  (newline))

(def (flag? flag args)
  (member flag args))

(def (option flag args)
  (match args
    ([] #f)
    ([hd value . rest]
     (if (equal? hd flag) value (option flag (cons value rest))))
    ([_] #f)))

(def (options flag args)
  (match args
    ([] '())
    ([hd value . rest]
     (if (equal? hd flag)
       (cons value (options flag rest))
       (options flag (cons value rest))))
    ([_] '())))

(def (positional-args args)
  (let lp ((rest args) (out '()))
    (match rest
      ([] (reverse out))
      ([hd value . more]
       (cond
        ((member hd '("--json" "--code" "--names-only" "--changed" "--full"))
         (lp (cons value more) out))
        ((member hd '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"))
         (lp more out))
        ((string-prefix? "--" hd)
         (lp (cons value more) out))
        (else
         (lp (cons value more) (cons hd out)))))
      ([hd]
       (if (string-prefix? "--" hd) (reverse out) (reverse (cons hd out)))))))

(def (project-root args)
  (let (pos (positional-args args))
    (if (and (pair? pos) (file-directory? (last pos)))
      (last pos)
      ".")))

(def (drop-project-root args)
  (let* ((pos (positional-args args))
         (root? (and (pair? pos) (file-directory? (last pos))))
         (root (and root? (last pos))))
    (if root?
      (filter (lambda (arg) (not (equal? arg root))) args)
      args)))

(def (file-directory? path)
  (eq? (file-type path) 'directory))

(def (relative-path root path)
  (let* ((root* (path-normalize root))
         (path* (path-normalize path))
         (prefix (if (string-suffix? "/" root*) root* (string-append root* "/"))))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

(def (normalize-owner owner)
  (if (string-prefix? "./" owner)
    (substring owner 2 (string-length owner))
    owner))

(def (dedupe xs)
  (let lp ((rest xs) (seen '()) (out '()))
    (match rest
      ([] (reverse out))
      ([hd . tl]
       (if (member hd seen)
         (lp tl seen out)
         (lp tl (cons hd seen) (cons hd out)))))))

(def (take* xs n)
  (if (or (zero? n) (null? xs))
    '()
    (cons (car xs) (take* (cdr xs) (fx1- n)))))

(def (last xs)
  (if (null? (cdr xs)) (car xs) (last (cdr xs))))

(def (join xs sep)
  (match xs
    ([] "")
    ([hd . rest]
     (let lp ((rest rest) (out hd))
       (match rest
         ([] out)
         ([item . more] (lp more (string-append out sep item))))))))

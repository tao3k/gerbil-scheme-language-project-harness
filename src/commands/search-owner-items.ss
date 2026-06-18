;;; -*- Gerbil -*-
;;; Owner-items rendering over definitions plus parser-owned owner facts.

(import :parser/owner-items
        :support/args
        :support/list
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter filter-map ormap))

(export emit-owner-items
        emit-owner-items-command
        matching-owner-syntax-facts
        owner-item-query-terms)

;; Integer
(def +owner-items-default-limit+ 80)

;;; CLI boundary:
;;; - This command is the fast owner-items materializer behind search owner.
;;; - It validates unsupported output modes before touching parser facts.
;; : (-> Args ExitCode )
(def (emit-owner-items-command args)
  (let (args (if (and (pair? args) (equal? (car args) "search"))
              (cdr args)
              args))
    (when (flag? "--code" args)
      (error "fast owner-items does not handle --code"))
    (when (flag? "--json" args)
      (error "fast owner-items does not handle --json"))
    (let* ((root (path-normalize (project-root args)))
           (args (drop-project-root args))
           (positionals (positional-args args))
           (owner (and (pair? positionals) (car positionals)))
           (items? (and (pair? (cdr positionals))
                        (equal? (cadr positionals) "items"))))
      (unless owner (error "search owner requires a path"))
      (unless items? (error "fast owner-items requires the items view"))
      (let* ((file (parse-explicit-owner-items-file root owner))
             (query (option "--query" args))
             (terms (owner-item-query-terms query))
             (limit (owner-items-limit args))
             (definition-matches
              (matching-definitions (source-file-definitions file) terms))
             (syntax-limit (max 0 (- limit (length definition-matches))))
             (syntax-matches
              (matching-owner-syntax-facts file terms syntax-limit)))
        (if (flag? "--names-only" args)
          (begin
            (for-each (lambda (defn) (displayln (definition-name defn)))
                      (take* definition-matches limit))
            (for-each (lambda (fact) (displayln (hash-get fact 'name)))
                      syntax-matches))
          (emit-owner-items file definition-matches syntax-matches limit)))
      0)))

;;; Parse boundary:
;;; - Owner paths are resolved inside the requested project root.
;;; - The parser owner builds the source file; command code only validates path shape.
;; : (-> Root OwnerPath SourceFile )
(def (parse-explicit-owner-items-file root owner)
  (let (path (path-expand owner root))
    (unless (and (owner-items-source-path? path) (file-exists? path))
      (error "owner not found" owner))
    (parse-owner-items-source-file root path)))

;;; Limit boundary:
;;; - Missing limits use the public default.
;;; - Invalid numeric values fail before rendering partial output.
;; : (-> Args Nat )
(def (owner-items-limit args)
  (let* ((value (option "--limit" args))
         (parsed (and value (string->number value))))
    (cond
     ((not value) +owner-items-default-limit+)
     ((and (integer? parsed) (>= parsed 0)) parsed)
     (else (error "invalid owner-items --limit" value)))))

;;; Definition filter:
;;; - Empty term lists are an all-definitions owner browse.
;;; - Non-empty terms reuse the single-definition predicate below.
;; : (-> (List Definition) (List Term) (List Definition) )
(def (matching-definitions definitions terms)
  (if (null? terms)
    definitions
    (filter (cut definition-matches-any-term? <> terms) definitions)))

;;; Definition predicate:
;;; - Terms are alternatives, matching owner-items pipe semantics.
;;; - The predicate stays separate so syntax facts can use their own fields.
;; : (-> Definition (List Term) Boolean )
(def (definition-matches-any-term? defn terms)
  (ormap (cut definition-matches-term? defn <>) terms))

;;; Definition term predicate:
;;; - Match normalized parser-owned definition fields, not source text.
;;; - Selector matching keeps line-range searches available to agents.
;; : (-> Definition Term Boolean )
(def (definition-matches-term? defn term)
  (ormap (cut string-contains <> term)
         [(definition-name defn)
          (definition-kind defn)
          (definition-selector defn)]))

;;; Boundary:
;;; - Render definition matches before syntax facts so exact owner symbols stay first.
;;; - Syntax facts keep parser provenance visible instead of reading source text.
;;; Boundary:
;;; - Merge definition matches with parser-owned syntax facts for one owner.
;;; - Keep rendering line-oriented so ASP fast-path receipts stay compact.
;; : (-> SourceFile Matches SyntaxMatches Unit )
(def (emit-owner-items file definition-matches syntax-matches . maybe-limit)
  (let* ((limit (owner-items-effective-limit maybe-limit))
         (shown-definitions (take* definition-matches limit))
         (syntax-budget (max 0 (- limit (length shown-definitions))))
         (shown-syntax (take* syntax-matches syntax-budget)))
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (+ (length definition-matches)
                             (length syntax-matches))
             " shown=" (+ (length shown-definitions)
                           (length shown-syntax))
             " limit=" limit)
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   shown-definitions)
  (for-each emit-owner-syntax-item shown-syntax)))

(def (owner-items-effective-limit maybe-limit)
  (if (and (pair? maybe-limit) (car maybe-limit))
    (car maybe-limit)
    +owner-items-default-limit+))

;;; Boundary: syntax items preserve parser fact ownership while giving owner-items operator granularity.
;; : (-> SyntaxFact Unit )
(def (emit-owner-syntax-item fact)
  (displayln "|item kind=" (hash-get fact 'kind)
             " name=" (hash-get fact 'name)
             " selector=" (hash-get (hash-get fact 'location) 'path)
             ":" (hash-get (hash-get fact 'location) 'lineRange)
             " source=" (hash-get fact 'source)
             " languageKind=" (hash-get fact 'languageKind)
             " role=" (syntax-fact-field-string fact 'role)))

;;; Boundary:
;;; - Match against structural fields/queryKeys, not raw source text.
;;; - Preserve parser-owned fact provenance while filtering owner items.
;; : (-> SourceFile (List String) (List SyntaxFact) )
(def (matching-owner-syntax-facts file terms . maybe-limit)
  (let (facts (owner-items-syntax-fact-json file))
    (if (and (pair? maybe-limit) (car maybe-limit))
      (matching-owner-syntax-facts/limit facts terms (car maybe-limit) [])
      (filter (cut syntax-fact-matches-any-term? <> terms) facts))))

;; : (-> (List SyntaxFact) (List String) Integer (List SyntaxFact) (List SyntaxFact) )
(def (matching-owner-syntax-facts/limit facts terms remaining out)
  (cond
   ((or (null? facts) (<= remaining 0))
    (reverse out))
   ((syntax-fact-matches-any-term? (car facts) terms)
    (matching-owner-syntax-facts/limit
     (cdr facts) terms (- remaining 1) (cons (car facts) out)))
   (else
    (matching-owner-syntax-facts/limit
     (cdr facts) terms remaining out))))

;;; Boundary:
;;; - Empty term lists intentionally match all syntax facts for owner browsing.
;;; - Non-empty terms keep predicate matching isolated to one fact at a time.
;; : (-> SyntaxFact (List String) Boolean )
(def (syntax-fact-matches-any-term? fact terms)
  (or (null? terms)
      (ormap (cut syntax-fact-matches-term? fact <>) terms)))

;;; Boundary:
;;; - This predicate searches normalized syntax fact fields only.
;;; - Query semantics stay independent from source text formatting.
;; : (-> SyntaxFact String Boolean )
(def (syntax-fact-matches-term? fact term)
  (ormap (cut string-contains <> term)
         (filter string?
                 (append [(hash-get fact 'kind)
                          (hash-get fact 'name)
                          (hash-get fact 'languageKind)
                          (hash-get fact 'ownerPath)]
                         (hash-get fact 'queryKeys)
                         (syntax-fact-field-values fact)))))

;;; Boundary:
;;; - Flatten selected structured fields into string search keys.
;;; - Keep unsupported field values out of the match surface.
;; : (-> SyntaxFact (List String) )
(def (syntax-fact-field-values fact)
  (let (fields (hash-get fact 'fields))
    (if fields
      (filter-map (lambda (key)
                    (let (value (hash-get fields key))
                      (cond
                       ((string? value) value)
                       ((number? value) (number->string value))
                       (else #f))))
                  '(role generic receiver receiverType syntaxHead operator
                         slotCacheRole cacheOperation sourceSelector))
      '())))

;; : (-> SyntaxFact Key String )
(def (syntax-fact-field-string fact key)
  (let* ((fields (hash-get fact 'fields))
         (value (and fields (hash-get fields key))))
    (cond
     ((string? value) value)
     ((number? value) (number->string value))
     (else ""))))

;;; Boundary:
;;; - Owner item queries accept pipe and whitespace alternatives.
;;; - Empty query strings remain an explicit all-items request.
;; : (-> MaybeString (List String) )
(def (owner-item-query-terms query)
  (if query
    (filter owner-item-query-term? (split-owner-item-query query))
    '()))

;; : (-> String Boolean )
(def (owner-item-query-term? value)
  (and (string? value)
       (> (string-length value) 0)))

;;; Boundary:
;;; - Split only the owner-items query grammar, not global search parsing.
;;; - The helper recursion keeps token state explicit without named-let loops.
;; : (-> String (List String) )
(def (split-owner-item-query query)
  (split-owner-item-query/chars (string->list query) [] []))

;; : (-> (List Char) (List Char) (List String) (List String) )
(def (split-owner-item-query/chars chars token out)
  (cond
   ((null? chars)
    (reverse (cons-owner-query-token/chars token out)))
   ((owner-item-query-separator? (car chars))
    (split-owner-item-query/chars
     (cdr chars) [] (cons-owner-query-token/chars token out)))
   (else
    (split-owner-item-query/chars (cdr chars) (cons (car chars) token) out))))

;; : (-> (List Char) (List String) (List String) )
(def (cons-owner-query-token/chars token out)
  (if (null? token)
    out
    (cons (list->string (reverse token)) out)))

;; : (-> Char Boolean )
(def (owner-item-query-separator? char)
  (or (char=? char #\|)
      (char=? char #\space)
      (char=? char #\tab)
      (char=? char #\newline)
      (char=? char #\return)))

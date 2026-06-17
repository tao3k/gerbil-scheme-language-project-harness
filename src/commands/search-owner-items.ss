;;; -*- Gerbil -*-
;;; Owner-items rendering over definitions plus parser-owned structural facts.

(import :parser/facade
        :protocol/structural-facts
        :support/io
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter filter-map ormap))

(export emit-owner-items
        matching-owner-syntax-facts
        owner-item-query-terms)

;;; Boundary:
;;; - Render definition matches before syntax facts so exact owner symbols stay first.
;;; - Syntax facts keep parser provenance visible instead of reading source text.
;;; Boundary:
;;; - Merge definition matches with parser-owned syntax facts for one owner.
;;; - Keep rendering line-oriented so ASP fast-path receipts stay compact.
;; Unit <- SourceFile Matches SyntaxMatches
(def (emit-owner-items file definition-matches syntax-matches)
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (+ (length definition-matches)
                             (length syntax-matches)))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   definition-matches)
  (for-each emit-owner-syntax-item syntax-matches))

;;; Boundary: syntax items preserve parser fact ownership while giving owner-items operator granularity.
;; Unit <- SyntaxFact
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
;; (List SyntaxFact) <- SourceFile (List String)
(def (matching-owner-syntax-facts file terms)
  (filter (cut syntax-fact-matches-any-term? <> terms)
          (structural-syntax-fact-json file)))

;;; Boundary:
;;; - Empty term lists intentionally match all syntax facts for owner browsing.
;;; - Non-empty terms keep predicate matching isolated to one fact at a time.
;; Boolean <- SyntaxFact (List String)
(def (syntax-fact-matches-any-term? fact terms)
  (or (null? terms)
      (ormap (cut syntax-fact-matches-term? fact <>) terms)))

;;; Boundary:
;;; - This predicate searches normalized syntax fact fields only.
;;; - Query semantics stay independent from source text formatting.
;; Boolean <- SyntaxFact String
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
;; (List String) <- SyntaxFact
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

;; String <- SyntaxFact Key
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
;; (List String) <- MaybeString
(def (owner-item-query-terms query)
  (if query
    (filter owner-item-query-term? (split-owner-item-query query))
    '()))

;; Boolean <- String
(def (owner-item-query-term? value)
  (and (string? value)
       (> (string-length value) 0)))

;;; Boundary:
;;; - Split only the owner-items query grammar, not global search parsing.
;;; - The helper recursion keeps token state explicit without named-let loops.
;; (List String) <- String
(def (split-owner-item-query query)
  (split-owner-item-query/chars (string->list query) [] []))

;; (List String) <- (List Char) (List Char) (List String)
(def (split-owner-item-query/chars chars token out)
  (cond
   ((null? chars)
    (reverse (cons-owner-query-token/chars token out)))
   ((owner-item-query-separator? (car chars))
    (split-owner-item-query/chars
     (cdr chars) [] (cons-owner-query-token/chars token out)))
   (else
    (split-owner-item-query/chars (cdr chars) (cons (car chars) token) out))))

;; (List String) <- (List Char) (List String)
(def (cons-owner-query-token/chars token out)
  (if (null? token)
    out
    (cons (list->string (reverse token)) out)))

;; Boolean <- Char
(def (owner-item-query-separator? char)
  (or (char=? char #\|)
      (char=? char #\space)
      (char=? char #\tab)
      (char=? char #\newline)
      (char=? char #\return)))

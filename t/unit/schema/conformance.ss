;;; -*- Gerbil -*-
(import :commands/search
        :std/misc/ports
        :std/srfi/13
        :std/test
        :std/text/json)

(export check-runtime-source-json-schema-conformance
        check-extension-pattern-json-schema-conformance
        check-compare-json-schema-conformance
        check-structural-index-json-schema-conformance)

(def (json-get table key)
  (hash-get table (if (string? key) (string->symbol key) key)))

(def (search-json args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    (call-with-input-string output read-json)))

(def (schema-json file)
  (call-with-input-file (string-append "schemas/" file) read-json))

(def (check-packet-conforms-to-schema! packet schema-file)
  (let (schema (schema-json schema-file))
    (check (missing-required-fields packet schema) => [])
    (for-each
     (lambda (entry)
       (check (json-get packet (car entry)) => (cdr entry)))
     (top-level-const-fields schema))))

(def (missing-required-fields packet schema)
  (filter (lambda (key)
            (not (hash-key? packet (string->symbol key))))
          (json-get schema "required")))

(def (top-level-const-fields schema)
  (filter-map
   (lambda (entry)
     (let (property (cdr entry))
       (and (hash-table? property)
            (hash-key? property "const")
            (cons (car entry) (json-get property "const")))))
   (hash->list (json-get schema "properties"))))

(def (check-runtime-source-json-schema-conformance)
  (let* ((packet (search-json ["runtime-source" "writeenv" "printer" "hook" "--json" "."]))
         (source-ref (json-get packet "sourceRef"))
         (acquisition (json-get packet "acquisition"))
         (selector-resolver (json-get packet "selectorResolver"))
         (source-examples (json-get packet "sourceExamples"))
         (source-comments (json-get packet "sourceComments"))
         (facts (json-get packet "facts"))
         (fact (car facts)))
    (check-packet-conforms-to-schema!
     packet
     "semantic-runtime-source-acquisition.v1.schema.json")
    (check (json-get packet "quality") => "version-matched-source-plan")
    (check (string-prefix? "search runtime-source " (json-get packet "next")) => #t)
    (check (json-get source-ref "checkoutPolicy") => "exact-tag-from-active-runtime")
    (check (json-get source-ref "statePathPolicy") => "asp-state-managed")
    (check (json-get acquisition "owner") => "asp")
    (check (json-get acquisition "indexOwner") => "asp-structural-index")
    (check (json-get selector-resolver "output") => "code-with-comments")
    (check (not (null? source-examples)) => #t)
    (check (not (null? source-comments)) => #t)
    (check (json-get fact "id") => "gerbil-runtime-writeenv-source")
    (check (not (null? (json-get fact "selectors"))) => #t)
    (check (not (null? (json-get packet "failureCases"))) => #t)
    (check (not (null? (json-get packet "qualitySignals"))) => #t)))

(def (check-extension-pattern-json-schema-conformance)
  (let* ((packet (search-json ["pattern" "poo" "json" "fallback" "--json" "."]))
         (mapping (json-get packet "patternMapping"))
         (source-ref (json-get mapping "sourceRef")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-extension-pattern-mapping.v1.schema.json")
    (check (json-get packet "quality") => "partial")
    (check (json-get packet "missing") => ["writeenv-roundtrip-witness"])
    (check (string-prefix? "search " (json-get packet "next")) => #t)
    (check (json-get mapping "id") => "poo-io-json-fallback")
    (check (json-get source-ref "pathPolicy") => "runtime-resolved")
    (check (not (null? (json-get mapping "selectors"))) => #t)
    (check (not (null? (json-get mapping "minimalForms"))) => #t)
    (check (not (null? (json-get mapping "failureCases"))) => #t)
    (check (not (null? (json-get mapping "qualitySignals"))) => #t)))

(def (check-compare-json-schema-conformance)
  (let* ((packet (search-json ["compare" "env" "active" "documented" "--json" "."]))
         (comparisons (json-get packet "comparisons"))
         (comparison (car comparisons))
         (left (json-get comparison "left"))
         (right (json-get comparison "right")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-compare-packet.v1.schema.json")
    (check (json-get packet "quality") => "verified")
    (check (json-get packet "missing") => [])
    (check (json-get comparison "id") => "env-active-documented")
    (check (json-get comparison "result") => "active-runtime-authoritative")
    (check (json-get left "kind") => "active-runtime")
    (check (json-get right "status") => "non-authoritative")
    (check (not (null? (json-get comparison "failureCases"))) => #t)
    (check (not (null? (json-get comparison "qualitySignals"))) => #t)))

(def (check-structural-index-json-schema-conformance)
  (let* ((packet (search-json ["structural" "--json" "."]))
         (syntax-facts (json-get packet "syntaxFacts"))
         (macro-fact (find-syntax-fact syntax-facts "macro" "capture-safe"))
         (import-fact (find-syntax-fact syntax-facts "import" ":std/text/json"))
         (binding-fact (find-syntax-fact syntax-facts "binding" "again"))
         (class-fact (find-syntax-fact syntax-facts "class" "<Widget>"))
         (method-fact (find-syntax-fact syntax-facts "method" ":render"))
         (case-lambda-fact
          (find-syntax-fact-field syntax-facts
                                  "function"
                                  "case-lambda"
                                  "role"
                                  "multi-arity-function"))
         (map-fact
          (find-syntax-fact-field syntax-facts
                                  "call"
                                  "map"
                                  "role"
                                  "sequence-map")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-structural-index.v1.schema.json")
    (check (json-get packet "rawSourceStored") => #f)
    (check (not (null? syntax-facts)) => #t)
    (check (json-get macro-fact "source") => "native-parser")
    (check (json-get macro-fact "languageKind") => "defsyntax")
    (check (json-get import-fact "languageKind") => "module-import")
    (check (json-get binding-fact "languageKind") => "let*")
    (check (json-get (json-get class-fact "fields") "slots")
           => ["name" "count"])
    (check (json-get (json-get method-fact "fields") "receiverType")
           => "<Widget>")
    (check (json-get (json-get method-fact "fields") "specializers")
           => ["widget:<Widget>"])
    (check (json-get (json-get method-fact "fields") "dispatchArity")
           => 1)
    (check (json-get (json-get case-lambda-fact "fields") "arities")
           => [0 1])
    (check (json-get (json-get map-fact "fields") "operandCount")
           => 2)))

(def (find-syntax-fact facts kind name)
  (or (find (lambda (fact)
              (and (equal? (json-get fact "kind") kind)
                   (equal? (json-get fact "name") name)))
            facts)
      (error "syntax fact not found" kind name)))

(def (find-syntax-fact-field facts kind name field expected)
  (or (find (lambda (fact)
              (and (equal? (json-get fact "kind") kind)
                   (equal? (json-get fact "name") name)
                   (let (fields (json-get fact "fields"))
                     (and fields
                          (equal? (json-get fields field) expected)))))
            facts)
      (error "syntax fact field not found" kind name field expected)))

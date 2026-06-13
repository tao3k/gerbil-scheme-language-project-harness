;;; -*- Gerbil -*-
(import :commands/search
        :std/misc/ports
        :std/srfi/13
        :std/test
        :std/text/json)

(export check-runtime-source-json-schema-conformance
        check-extension-pattern-json-schema-conformance
        check-compare-json-schema-conformance)

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
       (check (hash-get packet (car entry)) => (cdr entry)))
     (top-level-const-fields schema))))

(def (missing-required-fields packet schema)
  (filter (lambda (key)
            (not (hash-key? packet key)))
          (hash-get schema "required")))

(def (top-level-const-fields schema)
  (filter-map
   (lambda (entry)
     (let (property (cdr entry))
       (and (hash-table? property)
            (hash-key? property "const")
            (cons (car entry) (hash-get property "const")))))
   (hash->list (hash-get schema "properties"))))

(def (check-runtime-source-json-schema-conformance)
  (let* ((packet (search-json ["runtime-source" "writeenv" "printer" "hook" "--json" "."]))
         (source-ref (hash-get packet "sourceRef"))
         (acquisition (hash-get packet "acquisition"))
         (facts (hash-get packet "facts"))
         (fact (car facts)))
    (check-packet-conforms-to-schema!
     packet
     "semantic-runtime-source-acquisition.v1.schema.json")
    (check (hash-get packet "quality") => "version-matched-source-plan")
    (check (string-prefix? "search runtime-source " (hash-get packet "next")) => #t)
    (check (hash-get source-ref "checkoutPolicy") => "exact-tag-from-active-runtime")
    (check (hash-get source-ref "statePathPolicy") => "asp-state-managed")
    (check (hash-get acquisition "owner") => "asp")
    (check (hash-get acquisition "indexOwner") => "asp-structural-index")
    (check (hash-get fact "id") => "gerbil-runtime-writeenv-source")
    (check (not (null? (hash-get fact "selectors"))) => #t)
    (check (not (null? (hash-get packet "failureCases"))) => #t)
    (check (not (null? (hash-get packet "qualitySignals"))) => #t)))

(def (check-extension-pattern-json-schema-conformance)
  (let* ((packet (search-json ["pattern" "poo" "json" "fallback" "--json" "."]))
         (mapping (hash-get packet "patternMapping"))
         (source-ref (hash-get mapping "sourceRef")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-extension-pattern-mapping.v1.schema.json")
    (check (hash-get packet "quality") => "partial")
    (check (hash-get packet "missing") => ["writeenv-roundtrip-witness"])
    (check (string-prefix? "search " (hash-get packet "next")) => #t)
    (check (hash-get mapping "id") => "poo-io-json-fallback")
    (check (hash-get source-ref "pathPolicy") => "runtime-resolved")
    (check (not (null? (hash-get mapping "selectors"))) => #t)
    (check (not (null? (hash-get mapping "minimalForms"))) => #t)
    (check (not (null? (hash-get mapping "failureCases"))) => #t)
    (check (not (null? (hash-get mapping "qualitySignals"))) => #t)))

(def (check-compare-json-schema-conformance)
  (let* ((packet (search-json ["compare" "env" "active" "documented" "--json" "."]))
         (comparisons (hash-get packet "comparisons"))
         (comparison (car comparisons))
         (left (hash-get comparison "left"))
         (right (hash-get comparison "right")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-compare-packet.v1.schema.json")
    (check (hash-get packet "quality") => "verified")
    (check (hash-get packet "missing") => [])
    (check (hash-get comparison "id") => "env-active-documented")
    (check (hash-get comparison "result") => "active-runtime-authoritative")
    (check (hash-get left "kind") => "active-runtime")
    (check (hash-get right "status") => "non-authoritative")
    (check (not (null? (hash-get comparison "failureCases"))) => #t)
    (check (not (null? (hash-get comparison "qualitySignals"))) => #t)))

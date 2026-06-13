;;; -*- Gerbil -*-
(import :std/sort
        :std/srfi/13
        :std/test
        :std/text/json)
(export +schema-files+
        +local-schema-refs+
        schema-ref-closure
        missing-schema-files)

(def +schema-files+
  ["semantic-agent-hook-provider-manifest.v1.schema.json"
   "semantic-compare-packet.v1.schema.json"
   "semantic-content-compaction.v1.schema.json"
   "semantic-handle.v1.schema.json"
   "semantic-invariant-candidate.v1.schema.json"
   "semantic-extension-pattern-mapping.v1.schema.json"
   "semantic-runtime-source-acquisition.v1.schema.json"
   "semantic-language-registry.v1.schema.json"
   "semantic-native-syntax-fact-index.v1.schema.json"
   "semantic-structural-index.v1.schema.json"
   "semantic-query-packet.v1.schema.json"
   "semantic-read-packet.v1.schema.json"
   "semantic-search-packet.v1.schema.json"
   "semantic-source-location.v1.schema.json"
   "semantic-tree-sitter-provenance.v1.schema.json"
   "semantic-type-surface.v1.schema.json"])

(def +local-schema-refs+
  ["semantic-content-compaction.v1.schema.json"
   "semantic-handle.v1.schema.json"
   "semantic-invariant-candidate.v1.schema.json"
   "semantic-native-syntax-fact-index.v1.schema.json"
   "semantic-source-location.v1.schema.json"
   "semantic-tree-sitter-provenance.v1.schema.json"
   "semantic-type-surface.v1.schema.json"])

(def (schema-ref-closure)
  (sort (dedupe-strings
         (append-map schema-local-refs +schema-files+))
        string<?))

(def (schema-local-refs file)
  (collect-local-schema-refs
   (call-with-input-file (schema-path file) read-json)))

(def (collect-local-schema-refs value)
  (cond
   ((hash-table? value)
    (append-map
     (lambda (entry)
       (append (if (and (equal? (car entry) "$ref")
                        (string? (cdr entry)))
                 (local-schema-ref-list (cdr entry))
                 '())
               (collect-local-schema-refs (cdr entry))))
     (hash->list value)))
   ((list? value)
    (append-map collect-local-schema-refs value))
   (else '())))

(def (local-schema-ref-list ref)
  (let (path (local-schema-ref-path ref))
    (if path [path] '())))

(def (local-schema-ref-path ref)
  (if (or (string-prefix? "#" ref)
          (string-prefix? "http://" ref)
          (string-prefix? "https://" ref)
          (not (string-contains ref ".schema.json")))
    #f
    (let (hash-index (string-index ref #\#))
      (if hash-index
        (substring ref 0 hash-index)
        ref))))

(def (missing-schema-files files)
  (filter (lambda (file)
            (not (file-exists? (schema-path file))))
          files))

(def (schema-path file)
  (string-append "schemas/" file))

(def (append-map proc xs)
  (if (null? xs)
    '()
    (append (proc (car xs)) (append-map proc (cdr xs)))))

(def (dedupe-strings xs)
  (let lp ((rest xs) (seen '()) (out '()))
    (match rest
      ([] (reverse out))
      ([hd . tl]
       (if (member hd seen)
         (lp tl seen out)
         (lp tl (cons hd seen) (cons hd out)))))))

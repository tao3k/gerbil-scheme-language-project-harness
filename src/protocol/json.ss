;;; -*- Gerbil -*-
;;; JSON projections for Gerbil parser-owned facts.

(import :parser/parser
        :std/text/json
        :types/types)

(export source-file-json
        definition-json
        top-form-json
        finding-json
        parse-error-json
        write-json-line)

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
        (formals (definition-formals defn))
        (arity (definition-arity defn))
        (selector (definition-selector defn))))

(def (top-form-json form)
  (hash (kind (top-form-kind form))
        (head (top-form-head form))
        (path (top-form-path form))
        (start (top-form-start form))
        (end (top-form-end form))
        (selector (top-form-selector form))))

(def (finding-json finding)
  (hash (ruleId (type-finding-rule-id finding))
        (severity (type-finding-severity finding))
        (path (type-finding-path finding))
        (message (type-finding-message finding))
        (selector (type-finding-selector finding))
        (details (type-finding-details finding))))

(def (parse-error-json file)
  (hash (path (source-file-path file))
        (ruleId "GERBIL-SCHEME-READ-R001")
        (message (source-file-parse-error file))))

(def (write-json-line obj)
  (write-json obj)
  (newline))

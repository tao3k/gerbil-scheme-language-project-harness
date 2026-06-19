;;; -*- Gerbil -*-
;;; Downstream-facing validation facade for POO object field contracts.
;;; Boundary:
;;; - :extensions/poo-validation owns generic POO evidence shape validation.
;;; - :types/facade owns TypeSpec parsing and semantic validation.
;;; - This module composes those APIs for downstream module systems.

(import :gerbil/gambit
        (only-in :std/sugar hash)
        (only-in :extensions/poo-validation
                 poo-pattern-structural-validation)
        (only-in :types/facade
                 parse-type-sexpr
                 type->string
                 type-spec-valid?
                 type-validation-diagnostics))

(export poo-object-type-spec-validation
        poo-object-field-contract-validation
        poo-object-field-contracts-validation
        poo-object-contract-validation
        poo-object-validation-valid?)

(def +poo-object-contract-validation-schema+
  "poo-object-contract-validation/v1")

(def +poo-object-field-merge-kinds+
  '(override append prepend remove node-extend node-remove))

;; : (-> Any String)
(def (value->string value)
  (call-with-output-string ""
    (lambda (out) (write value out))))

;; : (-> String Any)
(def (string->datum value)
  (with-catch
   (lambda (_) value)
   (lambda ()
     (call-with-input-string value read))))

;; : (-> Any Any)
(def (type-expression-datum value)
  (cond
   ((symbol? value) value)
   ((string? value) (string->datum value))
   (else value)))

;; : (-> Any Boolean)
(def (metadata-list? value)
  (or (null? value)
      (and (list? value)
           (let loop ((rest value))
             (cond
              ((null? rest) #t)
              ((pair? (car rest)) (loop (cdr rest)))
              (else #f))))))

;; : (-> Symbol Boolean)
(def (merge-kind? value)
  (memq value +poo-object-field-merge-kinds+))

;; : (-> Any Symbol)
(def (base-type-name value-kind)
  (cond
   ((symbol? value-kind) value-kind)
   ((string? value-kind)
    (let (datum (string->datum value-kind))
      (and (symbol? datum) datum)))
   (else #f)))

;; : (-> Any Any Boolean)
(def (default-matches-type? value-kind value)
  (or (not value)
      (case (base-type-name value-kind)
        ((Any) #t)
        ((Symbol) (symbol? value))
        ((String) (string? value))
        ((List) (list? value))
        ((Boolean) (boolean? value))
        ((Number) (number? value))
        (else #t))))

;; : (-> Any Any Any Any (List String))
(def (field-contract-diagnostics field value-kind merge default metadata)
  (append
   (if (merge-kind? merge)
     []
     [(string-append "field:" (value->string field) ":unsupported-merge:"
                     (value->string merge))])
   (if (metadata-list? metadata)
     []
     [(string-append "field:" (value->string field)
                     ":metadata-not-association-list")])
   (if (default-matches-type? value-kind default)
     []
     [(string-append "field:" (value->string field)
                     ":default-not-compatible-with-type:"
                     (value->string value-kind))])))

;; : (-> Any Json)
(def (poo-object-type-spec-validation value-kind)
  (let* ((datum (type-expression-datum value-kind))
         (type-spec (parse-type-sexpr datum))
         (diagnostics
          (if type-spec
            (type-validation-diagnostics type-spec)
            [(string-append "type-expression:unparseable:"
                            (value->string value-kind))])))
    (hash (kind "poo-object-type-spec-validation")
          (schema +poo-object-contract-validation-schema+)
          (valueKind (value->string value-kind))
          (typeDisplay (and type-spec (type->string type-spec)))
          (valid (and type-spec
                      (type-spec-valid? type-spec)
                      (not (pair? diagnostics))))
          (diagnostics diagnostics))))

;; : (-> HashTable Symbol Any)
(def (hash-ref/default table key default)
  (let (value (hash-get table key))
    (if value value default)))

;; : (-> FieldContract Symbol Any)
(def (field-contract-ref field key . maybe-default)
  (let (default (if (null? maybe-default) #f (car maybe-default)))
    (cond
     ((hash-table? field) (hash-ref/default field key default))
     ((list? field)
      (let (entry (assoc key field))
        (if entry (cdr entry) default)))
     (else default))))

;; : (-> FieldContract Any)
(def (field-contract-id field)
  (or (field-contract-ref field 'field)
      (field-contract-ref field 'id)
      (field-contract-ref field 'identity)
      'unknown-field))

;; : (-> Any FieldContract SourceRef Json)
(def (poo-object-field-contract-validation object field source-ref)
  (let* ((field-id (field-contract-id field))
         (value-kind (field-contract-ref field 'valueKind
                                         (field-contract-ref field 'value-kind
                                                             'Any)))
         (merge (field-contract-ref field 'merge 'override))
         (default (field-contract-ref field 'default #f))
         (metadata (field-contract-ref field 'metadata '()))
         (type-validation (poo-object-type-spec-validation value-kind))
         (structural-validation
          (poo-pattern-structural-validation 'type-validation source-ref))
         (diagnostics
          (append (hash-get type-validation 'diagnostics)
                  (field-contract-diagnostics field-id
                                              value-kind
                                              merge
                                              default
                                              metadata))))
    (hash (kind "poo-object-field-contract-validation")
          (schema +poo-object-contract-validation-schema+)
          (object object)
          (field field-id)
          (valueKind (value->string value-kind))
          (merge merge)
          (typeValidation type-validation)
          (structuralValidation structural-validation)
          (valid (and (hash-get type-validation 'valid)
                      (hash-get structural-validation 'valid)
                      (not (pair? diagnostics))))
          (diagnostics diagnostics)
          (checkedSignals
           ["poo-pattern-structural-validation"
            "typespec-validation"
            "field-merge-kind"
            "field-default-kind"
            "field-metadata-shape"]))))

;; : (-> Json Boolean)
(def (poo-object-validation-valid? validation)
  (and (hash-table? validation)
       (hash-get validation 'valid)))

;; : (-> (List Json) Boolean)
(def (validations-valid? validations)
  (cond
   ((null? validations) #t)
   ((poo-object-validation-valid? (car validations))
    (validations-valid? (cdr validations)))
   (else #f)))

;; : (-> (List (List Any)) (List Any))
(def (append-lists lists)
  (if (null? lists)
    []
    (apply append lists)))

;; : (-> Any (List FieldContract) SourceRef Json)
(def (poo-object-field-contracts-validation object fields source-ref)
  (let* ((validations
          (map (lambda (field)
                 (poo-object-field-contract-validation object field source-ref))
               fields))
         (diagnostics
          (append-lists (map (lambda (validation)
                               (hash-get validation 'diagnostics))
                             validations))))
    (hash (kind "poo-object-field-contracts-validation")
          (schema +poo-object-contract-validation-schema+)
          (object object)
          (fieldValidations validations)
          (valid (validations-valid? validations))
          (diagnostics diagnostics))))

;; : (-> Any (List FieldContract) SourceRef Json)
(def (poo-object-contract-validation object fields source-ref)
  (let* ((structural-validation
          (poo-pattern-structural-validation 'type-validation source-ref))
         (field-contracts-validation
          (poo-object-field-contracts-validation object fields source-ref))
         (diagnostics
          (append (hash-get structural-validation 'diagnostics)
                  (hash-get field-contracts-validation 'diagnostics))))
    (hash (kind "poo-object-contract-validation")
          (schema +poo-object-contract-validation-schema+)
          (object object)
          (structuralValidation structural-validation)
          (fieldContractsValidation field-contracts-validation)
          (valid (and (hash-get structural-validation 'valid)
                      (hash-get field-contracts-validation 'valid)
                      (not (pair? diagnostics))))
          (diagnostics diagnostics)
          (checkedSignals
           ["poo-pattern-structural-validation"
            "field-contracts-validation"]))))

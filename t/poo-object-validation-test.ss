;;; -*- Gerbil -*-
;;; Tests for downstream-facing POO object contract validation facade.

(import :std/test
        (only-in :std/sugar hash)
        :gslph/src/extensions/facade)

(export poo-object-validation-test)

(def source-ref
  (hash (kind "dependency")
        (manager "gerbil.pkg")
        (dependency "github.com/tao3k/poo-flow")
        (repository "github.com/tao3k/poo-flow")
        (localSource "src/modules")
        (repositorySource "src/modules")
        (indexHint "poo-flow-module-object")
        (pathPolicy "package-dependency")
        (selectorScheme "gerbil-poo")))

(def good-field
  (hash (field 'backend)
        (valueKind 'Symbol)
        (merge 'override)
        (default 'nono)
        (metadata '((scope . sandbox)))))

(def bad-field
  (hash (field 'broken)
        (valueKind '(List String Symbol))
        (merge 'merge-strategy)
        (default 42)
        (metadata 'not-an-alist)))

(def (receipt-ref receipt key)
  (hash-get receipt key))

(def poo-object-validation-test
  (test-suite "poo object contract validation facade"
    (test-case "validates a downstream field contract"
      (let* ((validation
              (poo-object-field-contract-validation
               'objects.nono-sandbox.sandbox
               good-field
               source-ref))
             (type-validation
              (receipt-ref validation 'typeValidation))
             (structural-validation
              (receipt-ref validation 'structuralValidation)))
        (check-equal? (receipt-ref validation 'kind)
                      "poo-object-field-contract-validation")
        (check-equal? (receipt-ref validation 'valid) #t)
        (check-equal? (receipt-ref type-validation 'valid) #t)
        (check-equal? (receipt-ref structural-validation 'patternKind)
                      "type-validation")))

    (test-case "reports bad field contract evidence"
      (let* ((validation
              (poo-object-field-contract-validation
               'objects.validation.broken
               bad-field
               source-ref))
             (diagnostics
              (receipt-ref validation 'diagnostics)))
        (check-equal? (receipt-ref validation 'valid) #f)
        (check-equal? (not (null? diagnostics)) #t)))

    (test-case "aggregates field contract validations for an object"
      (let* ((validation
              (poo-object-contract-validation
               'objects.nono-sandbox.sandbox
               (list good-field)
               source-ref))
             (field-contracts
              (receipt-ref validation 'fieldContractsValidation)))
        (check-equal? (receipt-ref validation 'kind)
                      "poo-object-contract-validation")
        (check-equal? (receipt-ref validation 'valid) #t)
        (check-equal? (length (receipt-ref field-contracts 'fieldValidations))
                      1)))))

(run-tests! poo-object-validation-test)

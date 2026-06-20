;;; -*- Gerbil -*-
;;; Tests for downstream-facing generic TypeSpec contract validation.

(import :gerbil/gambit
        :std/test
        :gslph/src/types/facade)

(export type-validation-facade-test)

(def (receipt-ref receipt key)
  (hash-get receipt key))

(def type-validation-facade-test
  (test-suite "type validation facade"
    (test-case "exports structured contract validation packets downstream"
      (let* ((validation
              (type-contract-structural-validation "(Hash String)"))
             (diagnostic-facts
              (receipt-ref validation 'diagnosticFacts))
             (diagnostic
              (car diagnostic-facts)))
        (check (receipt-ref validation 'kind)
               => "type-contract-structural-validation")
        (check (receipt-ref validation 'schema)
               => "type-contract-structural-validation/v1")
        (check (receipt-ref validation 'inputKind) => "contract")
        (check (receipt-ref validation 'valid) => #f)
        (check (receipt-ref validation 'typeDisplay)
               => "(hash String unknown)")
        (check (receipt-ref validation 'diagnostics)
               => ["hash-value:unknown-type"])
        (check (hash-get diagnostic 'code) => "unknown-type")
        (check (hash-get diagnostic 'path) => ["hash-value"])
        (check (hash-get diagnostic 'category) => "shape")
        (check (hash-get diagnostic 'message)
               => "hash-value:unknown-type")))

    (test-case "exports parsed TypeSpec and sexpr validation packets downstream"
      (let* ((list-validation
              (type-spec-structural-validation
               (parse-type-contract "(List Number)")))
             (values-validation
              (type-sexpr-structural-validation '(Values))))
        (check (receipt-ref list-validation 'kind)
               => "type-spec-structural-validation")
        (check (receipt-ref list-validation 'inputKind) => "typespec")
        (check (receipt-ref list-validation 'valid) => #t)
        (check (receipt-ref list-validation 'diagnosticFacts) => [])
        (check (receipt-ref values-validation 'kind)
               => "type-sexpr-structural-validation")
        (check (receipt-ref values-validation 'inputKind) => "sexpr")
        (check (receipt-ref values-validation 'valid) => #f)
        (check (receipt-ref values-validation 'diagnostics)
               => ["values-requires-at-least-one-value"])))))

(run-tests! type-validation-facade-test)

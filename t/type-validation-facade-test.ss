;;; -*- Gerbil -*-
;;; Tests for downstream-facing TypeSpec validation exports.

(import :std/test
        :gslph/src/types/facade)

(export type-validation-facade-test)

(def type-validation-facade-test
  (test-suite "type validation facade"
    (test-case "exports existing structured diagnostic APIs downstream"
      (let* ((bad-hash (parse-type-contract "(Hash String)"))
             (diagnostics (type-validation-diagnostics bad-hash))
             (facts (type-validation-diagnostic-facts bad-hash))
             (diagnostic (car facts)))
        (check (type-spec-valid? bad-hash) => #f)
        (check diagnostics => ["hash-value:unknown-type"])
        (check (type-validation-diagnostic-code diagnostic)
               => "unknown-type")
        (check (type-validation-diagnostic-path diagnostic)
               => ["hash-value"])
        (check (type-validation-diagnostic-category diagnostic)
               => "shape")
        (check (type-validation-diagnostic-message diagnostic)
               => "hash-value:unknown-type")))))

(run-tests! type-validation-facade-test)

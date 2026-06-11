;;; -*- Gerbil -*-
;;; Arity checks over parser-owned call facts and native type signatures.

(import :checker/model
        :parser/parser
        :types/findings
        :types/model
        :types/signatures)

(export run-arity-checks
        call-arity-finding)

(def (run-arity-checks index signatures)
  (filter-map
   (lambda (call)
     (let (signature (signature-type-for (call-fact-callee call) signatures))
       (and signature (call-arity-finding call signature))))
   (project-calls index)))

(def (call-arity-finding call signature)
  (and (eq? (type-kind signature) 'function)
       (let* ((expected (length (type-params signature)))
              (actual (call-fact-arity call)))
         (and (not (fx= expected actual))
              (arity-mismatch-finding call expected actual signature)))))

(def (arity-mismatch-finding call expected actual signature)
  (let ((evidence
         (make-checker-evidence
          (call-fact-callee call) expected actual
          (call-fact-selector call) (type->string signature))))
    (make-type-finding
     (checker-rule-id +arity-rule+)
     (checker-rule-severity +arity-rule+)
     (call-fact-path call)
     (string-append "arity mismatch for " (call-fact-callee call)
                    ": expected " (number->string expected)
                    ", got " (number->string actual))
     (call-fact-selector call)
     (hash (callee (checker-evidence-callee evidence))
           (expectedArity (checker-evidence-expected evidence))
           (actualArity (checker-evidence-actual evidence))
           (signature (checker-evidence-signature evidence))))))

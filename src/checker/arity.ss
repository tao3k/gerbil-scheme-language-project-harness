;;; -*- Gerbil -*-
;;; Arity checks over parser-owned call facts and native type signatures.

(import :gslph/src/checker/model
        :gslph/src/parser/model
        (only-in :gslph/src/parser/selectors
                 call-fact-selector
                 project-calls)
        (only-in :std/sugar cut filter-map)
        :gslph/src/types/findings
        :gslph/src/types/model
        :gslph/src/types/signatures)

(export run-arity-checks
        call-arity-finding)

;; : (-> NativeSignatures CallFact (Maybe TypeFinding) )
(def (call-arity-finding/known-signature signatures call)
  (let (signature (signature-type-for (call-fact-callee call) signatures))
    (and signature (call-arity-finding call signature))))

;; run-arity-checks
;;   : (-> ProjectIndex NativeSignatures (List TypeFinding))
;;   | doc m%
;;       `run-arity-checks index signatures` returns arity mismatch findings
;;       for calls whose callee has a known native signature.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-arity-checks index native-signatures)
;;       ;; => arity findings
;;       ```
;;     %
(def (run-arity-checks index signatures)
  (filter-map (cut call-arity-finding/known-signature signatures <>)
              (project-calls index)))
;; : (-> CallFact NativeSignatures (Maybe TypeFinding) )
(def (call-arity-finding call signature)
  (and (eq? (type-kind signature) 'function)
       (let ((expected (length (type-params signature)))
             (actual (call-fact-arity call)))
         (and (not (fx= expected actual))
              (arity-mismatch-finding call expected actual signature)))))
;; : (-> CallFact ExpectedArity ActualArity NativeSignatures TypeFinding )
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

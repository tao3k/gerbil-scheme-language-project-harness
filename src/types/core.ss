;;; -*- Gerbil -*-
;;; Type-check dispatch for Gerbil source projects.

(import :checker/facade
        :parser/facade
        :policy/facade
        (only-in :std/sugar ormap)
        :types/env
        :types/findings)

(export type-status
        run-type-checks
        run-type-checks/signatures
        run-type-checks/whitelist
        source-file-type-findings)
;;; Boundary:
;;; - type-status composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) Status )
(def (type-status findings)
  (if (ormap non-info-finding? findings) "fail" "pass"))
;; : (-> TypeFinding Boolean )
(def (non-info-finding? finding)
  (not (equal? (type-finding-severity finding) "info")))
;; : (-> ProjectIndex (List TypeFinding) )
(def (run-type-checks index)
  (run-type-checks/signatures index '()))
;; : (-> ProjectIndex NativeSignatures (List TypeFinding) )
(def (run-type-checks/signatures index signatures)
  (run-type-checks/whitelist index signatures '()))
;;; Boundary:
;;; - run-type-checks/whitelist composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex NativeSignatures Whitelist (List TypeFinding) )
(def (run-type-checks/whitelist index signatures whitelist)
  (append
   (apply append (map source-file-type-findings (project-index-files index)))
   (type-env-findings (build-type-env/signatures index signatures))
   (run-checker-checks/whitelist index signatures whitelist)
   (run-policy-checks index)))
;; : (-> SourceFile (List TypeFinding) )
(def (source-file-type-findings file)
  (let (error (source-file-parse-error file))
    (if error
      [(make-type-finding "GERBIL-SCHEME-READ-R001"
                          "error"
                          (source-file-path file)
                          error
                          (source-file-path file)
                          #f)]
      '())))
;;; Boundary:
;;; - type-env-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) (List TypeFinding) )
(def (type-env-findings bindings)
  (map duplicate-binding-finding (duplicate-type-bindings bindings)))
;; : (-> Duplicate TypeFinding )
(def (duplicate-binding-finding duplicate)
  (let ((binding (car duplicate))
        (prior (cadr duplicate)))
    (make-type-finding "GERBIL-SCHEME-TYPE-E001"
                       "error"
                       (type-binding-path binding)
                       (string-append "duplicate type binding for " (type-binding-name binding))
                       (type-binding-selector binding)
                       (hash (firstSelector (type-binding-selector prior))
                             (duplicateSelector (type-binding-selector binding))))))

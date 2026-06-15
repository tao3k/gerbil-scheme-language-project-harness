;;; -*- Gerbil -*-
;;; Agent-facing POO policy checks.

(import :parser/facade
        :policy/agent-support
        :policy/model
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar filter filter-map hash ormap)
        :types/findings)

(export poo-direct-writeenv-findings
        poo-direct-writeenv-finding
        poo-io-runtime-witness-findings
        poo-io-runtime-witness-finding
        poo-object-model-findings
        poo-object-model-finding
        poo-method-shape-findings
        poo-method-shape-finding)
;; ConfigConstant
(def +manual-object-model-callees+
  '("hash" "make-hash-table" "list->hash-table"))
;;; Boundary:
;;; - poo-direct-writeenv-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (poo-direct-writeenv-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (and (direct-writeenv-call? call)
                        (poo-direct-writeenv-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))
;; Boolean <- CallFact
(def (direct-writeenv-call? call)
  (equal? (call-fact-callee call) "writeenv"))
;; TypeFinding <- SourceFile CallFact
(def (poo-direct-writeenv-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-direct-writeenv-rule+)
   (policy-rule-severity +agent-poo-direct-writeenv-rule+)
   (source-file-path file)
   "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first"
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))
;;; Boundary:
;;; - poo-io-runtime-witness-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (poo-io-runtime-witness-findings index)
  (filter-map
   (lambda (file)
     (and (index-source-runtime-file-path? index (source-file-path file))
          (poo-io-source-file? file)
          (poo-io-method-override-file? file)
          (poo-io-runtime-witness-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - poo-io-source-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- SourceFile
(def (poo-io-source-file? file)
  (ormap poo-io-import? (source-file-imports file)))
;; Boolean <- String
(def (poo-io-import? import)
  (or (equal? import ":clan/poo/io")
      (equal? import "clan/poo/io")
      (string-contains import "clan/poo/io")))
;;; Boundary:
;;; - poo-io-method-override-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- SourceFile
(def (poo-io-method-override-file? file)
  (or (ormap (lambda (form)
               (member (top-form-head form)
                       ["defmethod" ".defmethod"]))
             (source-file-forms file))
      (ormap (lambda (call)
               (member (call-fact-callee call)
                       ["defmethod" ".defmethod"]))
             (source-file-calls file))))
;; TypeFinding <- SourceFile
(def (poo-io-runtime-witness-finding file)
  (make-type-finding
   (policy-rule-id +agent-poo-io-runtime-witness-rule+)
   (policy-rule-severity +agent-poo-io-runtime-witness-rule+)
   (source-file-path file)
   "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified"
   (source-file-path file)
   (hash (next "search runtime-source writeenv printer hook")
         (requiredWitness "writeenv-roundtrip-witness"))))
;;; Boundary:
;;; - poo-object-model-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (poo-object-model-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (filter-map
                   (lambda (call)
                     (and (manual-object-model-call? index file call)
                          (poo-object-model-finding file call)))
                   (source-file-calls file)))
                (project-index-files index)))
    '()))
;; Boolean <- ProjectIndex SourceFile CallFact
(def (manual-object-model-call? index file call)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (null? (source-file-poo-forms file))
       (member (call-fact-callee call) +manual-object-model-callees+)
       (call-fact-caller call)
       (or (string-prefix? "make-" (call-fact-caller call))
           (string-prefix? "new-" (call-fact-caller call))
           (string-prefix? "build-" (call-fact-caller call)))))
;; TypeFinding <- SourceFile CallFact
(def (poo-object-model-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-object-model-rule+)
   (policy-rule-severity +agent-poo-object-model-rule+)
   (source-file-path file)
   (string-append "manual object constructor " (call-fact-caller call)
                  " uses " (call-fact-callee call)
                  " while POO/protocol capability is active; prefer parser-owned defclass/defgeneric/defmethod or cite why a raw data record is intentional")
   (call-fact-selector call)
   (hash (constructor (call-fact-caller call))
         (callee (call-fact-callee call))
         (selector (call-fact-selector call))
         (next "search pattern poo class"))))
;;; Boundary:
;;; - poo-method-shape-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (poo-method-shape-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (fact)
                   (and (equal? (poo-form-fact-role fact) "method")
                        (let (missing (poo-method-shape-missing index fact))
                          (and (pair? missing)
                               (poo-method-shape-finding file fact missing)))))
                 (source-file-poo-forms file)))
              (project-index-files index))))
;;; Boundary:
;;; - poo-method-shape-missing composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PooMethodShapeMissing <- ProjectIndex Fact
(def (poo-method-shape-missing index fact)
  (filter identity
          [(and (blank-string? (poo-form-fact-generic fact)) "generic")
           (and (not (blank-string? (poo-form-fact-generic fact)))
                (not (poo-generic-fact-exists? index (poo-form-fact-generic fact)))
                "defgeneric")
           (and (blank-string? (poo-form-fact-receiver-type fact)) "receiver-type")
           (and (not (blank-string? (poo-form-fact-receiver-type fact)))
                (not (poo-receiver-evidence-exists?
                      index
                      (poo-form-fact-receiver-type fact)))
                "defclass-or-defprotocol")]))
;;; Boundary:
;;; - poo-generic-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex Generic
(def (poo-generic-fact-exists? index generic)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "generic")
          (equal? (poo-form-fact-generic fact) generic)))
   (project-poo-forms index)))
;; Boolean <- ProjectIndex String
(def (poo-receiver-evidence-exists? index name)
  (or (poo-class-fact-exists? index name)
      (poo-protocol-fact-exists? index name)))
;; TypeFinding <- SourceFile Fact Missing
(def (poo-method-shape-finding file fact missing)
  (make-type-finding
   (policy-rule-id +agent-poo-method-shape-rule+)
   (policy-rule-severity +agent-poo-method-shape-rule+)
   (source-file-path file)
   (string-append "POO method " (poo-form-fact-name fact)
                  " is missing parser-owned "
                  (join-missing missing)
                  " facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")
   (poo-form-fact-selector fact)
   (hash (generic (or (poo-form-fact-generic fact) ""))
         (receiverType (or (poo-form-fact-receiver-type fact) ""))
         (missing missing)
         (next "search pattern poo class protocol"))))

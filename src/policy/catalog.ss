;;; -*- Gerbil -*-
;;; Central agent-facing policy rule catalog.

(import :policy/model
        :std/srfi/13
        :support/list)

(export agent-steering-facts
        agent-steering-rule-json
        agent-steering-rule-ids
        agent-steering-rule-id-string
        agent-rule-policy-lines)
;; (List Fact)
(def (agent-steering-facts)
  ["macroFacts"
   "bindingFacts"
   "pooFormFacts"
   "higherOrderFacts"
   "controlFlowFacts"
   "dependencyUsageFacts"])

;;; Boundary:
;;; - agent-steering-rule-json coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;;; : (List Hash) <-
;; Json
(def (agent-steering-rule-json)
  [(hash (id (policy-rule-id +agent-poo-direct-writeenv-rule+))
         (severity (policy-rule-severity +agent-poo-direct-writeenv-rule+))
         (topic "poo-direct-writeenv")
         (next "search runtime-source writeenv printer hook"))
   (hash (id (policy-rule-id +agent-poo-io-runtime-witness-rule+))
         (severity (policy-rule-severity +agent-poo-io-runtime-witness-rule+))
         (topic "poo-io-runtime-witness")
         (requires "runtime-source-backed writeenv/printer-hook witness"))
   (hash (id (policy-rule-id +agent-poo-method-shape-rule+))
         (severity (policy-rule-severity +agent-poo-method-shape-rule+))
         (topic "poo-method-shape")
         (requires "defgeneric plus defclass or defprotocol receiver evidence"))
   (hash (id (policy-rule-id +agent-functional-idiom-advice-rule+))
         (severity (policy-rule-severity +agent-functional-idiom-advice-rule+))
         (topic "functional-data-transform")
         (prefers "map/filter/fold/for/fold/cut for pure transforms")
         (keepsNamedLetWhen "IO/state/generator/continuation driver"))
   (hash (id (policy-rule-id +agent-poo-object-model-rule+))
         (severity (policy-rule-severity +agent-poo-object-model-rule+))
         (topic "manual-object-encoding")
         (requires "POO dependency or parser-owned POO facts should steer constructors toward defclass/defgeneric/defmethod/protocol"))
   (hash (id (policy-rule-id +agent-macro-runtime-source-witness-rule+))
         (severity (policy-rule-severity +agent-macro-runtime-source-witness-rule+))
         (topic "macro-runtime-source-witness")
         (next "search runtime-source macro sugar module-sugar"))
   (hash (id (policy-rule-id +agent-protocol-evidence-rule+))
         (severity (policy-rule-severity +agent-protocol-evidence-rule+))
         (topic "protocol-evidence")
         (next "search pattern poo protocol"))
   (hash (id (policy-rule-id +agent-typed-combinator-style-rule+))
         (severity (policy-rule-severity +agent-typed-combinator-style-rule+))
         (topic "typed-combinator-style")
         (next "guide --code --topic typed-combinator-style --intent style"))
   (hash (id (policy-rule-id +agent-controlled-branch-shape-rule+))
         (severity (policy-rule-severity +agent-controlled-branch-shape-rule+))
         (topic "controlled-branch-shape")
         (requires "repeated match branches should be fixed only after parser-owned policy evidence, using helpers or bounded selector pipelines"))])
;;; Boundary:
;;; - agent-steering-rule-ids composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String
(def (agent-steering-rule-ids)
  (map (cut hash-get <> 'id) (agent-steering-rule-json)))
;; String
(def +agent-rule-prefix+ "GERBIL-SCHEME-AGENT-")
;;; Boundary:
;;; - agent-steering-rule-id-string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String
(def (agent-steering-rule-id-string)
  (match (agent-steering-rule-ids)
    ([] "")
    ([first . rest]
     (join (cons first (map compact-agent-rule-id rest)) ","))))
;; String <- RuleId
(def (compact-agent-rule-id rule-id)
  (if (string-prefix? +agent-rule-prefix+ rule-id)
    (substring rule-id
               (string-length +agent-rule-prefix+)
               (string-length rule-id))
    rule-id))
;;; Boundary:
;;; - agent-rule-policy-lines composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String)
(def (agent-rule-policy-lines)
  (map agent-rule-policy-line (agent-steering-rule-json)))
;;; Boundary:
;;; - agent-rule-policy-line coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; String <- Rule
(def (agent-rule-policy-line rule)
  (let ((id (hash-get rule 'id))
        (topic (hash-get rule 'topic)))
    (cond
     ((equal? topic "poo-direct-writeenv")
      (string-append
       "|policy poo-direct-writeenv=" id
       " blocks raw writeenv calls until runtime-source writeenv/printer hook evidence is cited"))
     ((equal? topic "poo-io-runtime-witness")
      (string-append
       "|policy poo-io-runtime-witness=" id
       " keeps POO IO overrides partial until writeenv/printer-hook runtime witnesses exist"))
     ((equal? topic "poo-method-shape")
      (string-append
       "|policy poo-method-shape=" id
       " requires defmethod edits to have matching defgeneric plus defclass or defprotocol receiver evidence"))
     ((equal? topic "functional-data-transform")
      (string-append
       "|policy functional-data-transform=" id
       " steers pure data transforms toward map/filter/fold/for/fold/cut and keeps named let for IO/state/generator/continuation drivers"))
     ((equal? topic "manual-object-encoding")
      (string-append
       "|policy manual-object-encoding=" id
       " suggests POO/protocol constructors when dependency or parser-owned POO facts are active"))
     ((equal? topic "macro-runtime-source-witness")
      (string-append
       "|policy macro-runtime-source-witness=" id
       " requires macro edits to cite search runtime-source macro sugar module-sugar before changing transformers"))
     ((equal? topic "protocol-evidence")
      (string-append
       "|policy protocol-evidence=" id
       " requires protocol-oriented methods to cite parser-owned defprotocol/defclass evidence"))
     ((equal? topic "typed-combinator-style")
     (string-append
      "|policy typed-combinator-style=" id
       " requires three criteria: adjacent Haskell-like transform signature block, compact expression-level composition, and optimization-boundary comments for specialized branches"))
     ((equal? topic "controlled-branch-shape")
      (string-append
       "|policy controlled-branch-shape=" id
       " turns repeated match branches into a policy-triggered repair: split helpers or use bounded selector pipelines, preserve behavior, and avoid opportunistic style edits"))
     (else
      (string-append "|policy " topic "=" id)))))

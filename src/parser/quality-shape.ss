;;; -*- Gerbil -*-
;;; Parser-owned quality-shape facts derived from native call and control-flow facts.

(import :parser/model
        :std/srfi/13
        :std/sugar
        :support/list)

(export predicate-family-facts-from-source
        field-access-pattern-facts-from-source
        boolean-condition-facts-from-source
        loop-driver-facts-from-source)

;; (List String)
(def +field-access-callees+ '("field-string" "field-list-string" "hash-get"))
;; (List String)
(def +condition-callees+ '("member" "equal?" "not" ">" "<" ">=" "<=" "string=?" "string-contains"))
;; (List String)
(def +reader-driver-callees+ '("read" "read-line" "read-syntax"))

;;; Predicate family facts identify repeated one-argument predicate helpers over the same subject.
;;; They give policy enough native evidence to request a helper/combinator rewrite without reading raw source.
;; (List PredicateFamilyFact) <- Relpath Definitions Calls
(def (predicate-family-facts-from-source relpath definitions calls)
  (filter-map (cut predicate-family-fact-from-group relpath calls <>)
              (predicate-definition-groups definitions)))

;;; Grouping uses filter+fold so predicate-family evidence is stable and does
;;; not depend on policy-side scans. The grouped value keeps original
;;; definitions intact for later selector and repair payloads.
;; (List PredicateGroup) <- Definitions
(def (predicate-definition-groups definitions)
  (foldl add-predicate-definition-group '()
         (filter predicate-definition? definitions)))

;;; The accumulator is intentionally association-list shaped: it is small,
;;; deterministic under reverse-at-materialization, and easy for agent repair
;;; payloads to display without introducing another model struct.
;; PredicateGroup <- Definition PredicateGroups
(def (add-predicate-definition-group definition groups)
  (let* ((key (predicate-definition-subject definition))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons definition (cdr prior)))
            (remove-predicate-definition-group key groups))
      (cons (cons key [definition]) groups))))

;;; Removing before re-cons keeps the newest accumulated group unique while the
;;; outer fold stays expression-returning and avoids mutation.
;; PredicateGroups <- Subject PredicateGroups
(def (remove-predicate-definition-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; Boolean <- Definition
(def (predicate-definition? definition)
  (and (= (definition-arity definition) 1)
       (string-suffix? "?" (definition-name definition))
       (pair? (definition-formals definition))))

;; String <- Definition
(def (predicate-definition-subject definition)
  (car (definition-formals definition)))

;;; This is the family materializer, not the threshold policy.
;;; It requires enough native field evidence before producing a repair fact.
;;; Names and spans are preserved so agent repair can stay selector-bounded.
;; PredicateFamilyFact <- Relpath Calls PredicateGroup
(def (predicate-family-fact-from-group relpath calls group)
  (let* ((subject (car group))
         (definitions (reverse (cdr group)))
         (names (map definition-name definitions))
         (family-calls (filter (cut call-owned-by? <> names) calls))
         (field-access-calls (filter field-access-call? family-calls))
         (condition-calls (filter condition-call? family-calls))
         (repeated-callees (repeated-call-callees family-calls))
         (field-keys (unique-strings
                      (filter identity (map call-field-key field-access-calls)))))
    (and (>= (length definitions) 3)
         (>= (length field-access-calls) 3)
         (make-predicate-family-fact
          (string-append "predicate-family:" subject)
          "predicate-family"
          relpath
          (earliest-definition-start definitions)
          (latest-definition-end definitions)
          "repeated-predicate-family"
          subject
          names
          (length definitions)
          field-keys
          repeated-callees
          (length condition-calls)
          ["predicate-family-combinator-drift"
           "field-selector-helper-candidate"
           "gerbil-utils-combinator-style"]
          "extract field/role predicate helpers or a table-driven predicate combinator; preserve exported predicate names unless policy evidence permits"))))

;;; Field access facts expose repeated hash/field selectors independently from policy thresholds.
;; (List FieldAccessPatternFact) <- Relpath Calls
(def (field-access-pattern-facts-from-source relpath calls)
  (filter-map (cut field-access-pattern-fact-from-group relpath <>)
              (field-access-groups calls)))

;;; Field accesses are grouped independently from predicate families so search,
;;; snapshot, and policy can each consume the same native fact without
;;; re-deriving thresholds.
;; (List FieldAccessGroup) <- Calls
(def (field-access-groups calls)
  (foldl add-field-access-group '()
         (filter field-access-call? calls)))

;;; Unknown keys are retained as an explicit bucket; this keeps malformed or
;;; unsupported call shapes visible to policy instead of silently dropping
;;; parser evidence.
;; FieldAccessGroups <- CallFact FieldAccessGroups
(def (add-field-access-group call groups)
  (let* ((key (or (call-field-key call) "<unknown>"))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons call (cdr prior)))
            (remove-field-access-group key groups))
      (cons (cons key [call]) groups))))

;;; The remove/re-cons pattern mirrors predicate grouping and preserves a
;;; compact, mutation-free accumulator shape.
;; FieldAccessGroups <- FieldKey FieldAccessGroups
(def (remove-field-access-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;;; This materializer turns a grouped call bucket into search-ready selector
;;; evidence.
;;; Callers and accessors stay in fields so policy can explain the helper
;;; candidate without source reads.
;; FieldAccessPatternFact <- Relpath FieldAccessGroup
(def (field-access-pattern-fact-from-group relpath group)
  (let* ((field-key (car group))
         (calls (reverse (cdr group)))
         (callers (unique-strings
                   (filter identity (map call-fact-caller calls)))))
    (and (>= (length calls) 3)
         (make-field-access-pattern-fact
          (string-append "field-access:" field-key)
          "field-access-pattern"
          relpath
          (earliest-call-start calls)
          (latest-call-end calls)
          "repeated-field-access"
          field-key
          callers
          (length calls)
          (unique-strings (map call-fact-callee calls))
          ["field-selector-helper-candidate"
           "predicate-family-combinator-drift"]
          "centralize repeated field access behind a small selector helper before adding more predicate branches"))))

;;; Boolean condition facts keep individual predicate helpers queryable for repair payloads.
;; (List BooleanConditionFact) <- Relpath Definitions Calls
(def (boolean-condition-facts-from-source relpath definitions calls)
  (filter-map (cut boolean-condition-fact-from-definition relpath calls <>)
              (filter predicate-definition? definitions)))

;;; Individual condition facts keep predicate-level evidence available even
;;; when a family warning owns the repair decision.
;;; The filter/map chain preserves callees and field keys as compact native
;;; context for the model.
;; BooleanConditionFact <- Relpath Calls Definition
(def (boolean-condition-fact-from-definition relpath calls definition)
  (let* ((name (definition-name definition))
         (owned-calls (filter (cut call-owned-by? <> [name]) calls))
         (condition-calls (filter condition-call? owned-calls))
         (field-access-calls (filter field-access-call? owned-calls)))
    (and (>= (+ (length condition-calls) (length field-access-calls)) 2)
         (make-boolean-condition-fact
          name
          "boolean-condition"
          relpath
          (definition-start definition)
          (definition-end definition)
          "predicate-condition"
          name
          (definition-formals definition)
          (unique-strings (map call-fact-callee condition-calls))
          (unique-strings
           (filter identity (map call-field-key field-access-calls)))
          (+ (length condition-calls) (length field-access-calls))
          ["predicate-helper-candidate"]
          "keep this as a small expression-returning predicate or compose it through the predicate family helper"))))

;;; Loop driver facts classify named-let facts so policies can distinguish pure transforms from real drivers.
;; (List LoopDriverFact) <- Relpath Calls HigherOrderFacts ControlFlowFacts
(def (loop-driver-facts-from-source relpath calls higher-order-forms control-flow-forms)
  (map (cut loop-driver-fact-from-control-flow relpath calls higher-order-forms <>)
       (filter manual-loop-control-flow? control-flow-forms)))

;; LoopDriverFact <- Relpath Calls HigherOrderFacts ControlFlowFact
(def (loop-driver-fact-from-control-flow relpath calls higher-order-forms fact)
  (let* ((driver-kind (loop-driver-kind calls higher-order-forms fact))
         (quality-facets (loop-driver-quality-facets driver-kind)))
    (make-loop-driver-fact
     (control-flow-fact-name fact)
     "loop-driver"
     relpath
     (control-flow-fact-start fact)
     (control-flow-fact-end fact)
     "manual-loop-classification"
     (or (control-flow-fact-caller fact) "")
     driver-kind
     (control-flow-fact-binding-count fact)
     (control-flow-fact-body-form-count fact)
     quality-facets
     (loop-driver-advice driver-kind))))

;; String <- Calls HigherOrderFacts ControlFlowFact
(def (loop-driver-kind calls higher-order-forms fact)
  (let (caller (control-flow-fact-caller fact))
    (cond
     ((caller-has-callee? calls caller +reader-driver-callees+)
      "io-reader-driver")
     ((caller-has-higher-order? higher-order-forms caller)
      "higher-order-boundary")
     ((>= (control-flow-fact-binding-count fact) 4)
      "state-driver-candidate")
     (else "pure-transform-candidate"))))

;; (List QualityFacet) <- DriverKind
(def (loop-driver-quality-facets driver-kind)
  (cond
   ((equal? driver-kind "pure-transform-candidate")
    ["manual-loop-drift" "combinator-candidate"])
   ((equal? driver-kind "io-reader-driver")
    ["preserve-named-let-driver" "io-state-boundary"])
   ((equal? driver-kind "higher-order-boundary")
    ["preserve-named-let-driver" "higher-order-boundary"])
   (else ["state-driver-candidate"])))

;; String <- DriverKind
(def (loop-driver-advice driver-kind)
  (cond
   ((equal? driver-kind "pure-transform-candidate")
    "prefer fold/filter-map/map or predicate helpers if behavior is a pure data transform")
   ((equal? driver-kind "io-reader-driver")
    "preserve named let unless a runtime witness proves the IO state machine can be simplified")
   ((equal? driver-kind "higher-order-boundary")
    "preserve explicit loop shape when it is already coupled to a higher-order boundary")
   (else "preserve state-driver shape unless parser facts show a smaller combinator rewrite")))

;; Boolean <- CallFact (List String)
(def (call-owned-by? call names)
  (member (or (call-fact-caller call) "") names))

;; Boolean <- CallFact
(def (field-access-call? call)
  (member (call-fact-callee call) +field-access-callees+))

;; Boolean <- CallFact
(def (condition-call? call)
  (member (call-fact-callee call) +condition-callees+))

;; FieldKey <- CallFact
(def (call-field-key call)
  (let (args (call-fact-arguments call))
    (and (pair? args)
         (pair? (cdr args))
         (clean-field-key (cadr args)))))

;;; Field keys come from reader-token text, so this normalizes quoted symbols
;;; without pretending to evaluate arbitrary Scheme values.
;; FieldKey <- FieldArgumentToken
(def (clean-field-key value)
  (let (text (if (string? value) value ""))
    (cond
     ((and (> (string-length text) 1) (string-prefix? "'" text))
      (substring text 1 (string-length text)))
     (else text))))

;;; The map/filter composition returns only repeated callees for the repair
;;; summary.
;;; Full call facts stay separate so this helper cannot hide selector evidence
;;; from policy.
;; (List CalleeName) <- Calls
(def (repeated-call-callees calls)
  (map car
       (filter (lambda (entry) (>= (cdr entry) 2))
               (call-callee-counts calls))))

;;; Counting stays local to the parser fact producer so policy can stay about
;;; thresholds and repair strategy, not call aggregation mechanics.
;; (List CountEntry) <- Calls
(def (call-callee-counts calls)
  (foldl add-call-callee-count '() calls))

;;; Each fold step replaces the old bucket and returns a fresh count list,
;;; matching the gerbil-utils preference for small expression-level reducers.
;; CountEntries <- CallFact CountEntries
(def (add-call-callee-count call counts)
  (let* ((callee (call-fact-callee call))
         (prior (assoc callee counts)))
    (if prior
      (cons (cons callee (fx1+ (cdr prior)))
            (remove-call-callee-count callee counts))
      (cons (cons callee 1) counts))))

;;; This helper is the reducer's uniqueness gate.
;;; The filter shape exposes the accumulator invariant and keeps count updates
;;; mutation-free.
;; CountEntries <- CalleeName CountEntries
(def (remove-call-callee-count callee counts)
  (filter (lambda (entry) (not (equal? (car entry) callee))) counts))

;; Boolean <- ControlFlowFact
(def (manual-loop-control-flow? fact)
  (equal? (control-flow-fact-role fact) "manual-loop"))

;;; Driver classification checks call evidence through ormap so IO/runtime
;;; boundaries are preserved as witness-backed facts, not guessed from names in
;;; policy code.
;; Boolean <- Calls Caller (List Callee)
(def (caller-has-callee? calls caller callees)
  (ormap (lambda (call)
           (and (equal? (or (call-fact-caller call) "") (or caller ""))
                (member (call-fact-callee call) callees)))
         calls))

;;; Higher-order presence is used as a conservative boundary: if native facts
;;; already show combinator ownership, the loop classifier avoids suggesting a
;;; flattening rewrite.
;; Boolean <- HigherOrderFacts Caller
(def (caller-has-higher-order? facts caller)
  (ormap (lambda (fact)
           (equal? (or (higher-order-fact-caller fact) "") (or caller "")))
         facts))

;;; Min/max folds keep location spans deterministic across parser runs without
;;; sorting the original definitions.
;; Integer <- Definitions
(def (earliest-definition-start definitions)
  (foldl (lambda (definition start)
           (min start (definition-start definition)))
         (definition-start (car definitions))
         (cdr definitions)))

;;; The span end is paired with earliest-definition-start so a predicate family
;;; can be surfaced as one repair selector.
;; Integer <- Definitions
(def (latest-definition-end definitions)
  (foldl (lambda (definition end)
           (max end (definition-end definition)))
         (definition-end (car definitions))
         (cdr definitions)))

;;; Call spans use the same fold shape as definition spans, which keeps fact
;;; projection stable for field-access pattern evidence.
;; Integer <- Calls
(def (earliest-call-start calls)
  (foldl (lambda (call start)
           (min start (call-fact-start call)))
         (call-fact-start (car calls))
         (cdr calls)))

;;; The latest call endpoint completes the selector boundary for grouped call
;;; facts without reaching back into source text.
;; Integer <- Calls
(def (latest-call-end calls)
  (foldl (lambda (call end)
           (max end (call-fact-end call)))
         (call-fact-end (car calls))
         (cdr calls)))

;;; Order-preserving uniqueness keeps query keys predictable while allowing
;;; parser facts to append evidence from several native sources.
;; (List String) <- (List String)
(def (unique-strings values)
  (reverse
   (foldl (lambda (value out)
            (if (member value out)
              out
              (cons value out)))
          '()
          values)))

;;; -*- Gerbil -*-
;;; Agent-facing self-audit for repeated inline alist lookup.
;;; Repeated assq/cdr lookups are a common generated-code smell when a record,
;;; profile accessor, or source-backed fact would make the shape explicit.

(import :parser/facade
        :policy/model
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar filter hash ormap)
        :types/findings)

(export alist-access-findings
        alist-access-finding)

;; Integer
(def +alist-access-min-inline-lookups+ 2)

;;; Project traversal boundary:
;;; - Parser call facts own the syntax evidence.
;;; - The policy only groups repeated inline lookup shape per source owner.
;; : (-> ProjectIndex (List TypeFinding) )
(def (alist-access-findings index)
  (filter-map alist-access-finding
              (project-index-files index)))

;;; Threshold boundary:
;;; - One inline lookup can be a local bridge.
;;; - Repetition means the owner needs a record, profile accessor, or helper.
;; : (-> SourceFile MaybeTypeFinding )
(def (alist-access-finding file)
  (let (lookups (alist-inline-assq-cdr-calls file))
    (and (>= (length lookups) +alist-access-min-inline-lookups+)
         (make-type-finding
          (policy-rule-id +agent-alist-access-rule+)
          (policy-rule-severity +agent-alist-access-rule+)
          (source-file-path file)
          "repeated inline assq/cdr alist lookups hide a data model; use a record/defstruct, source-backed profile accessors, or one named lookup helper"
          (call-fact-selector (car lookups))
          (alist-access-details lookups)))))

;;; Lookup collection:
;;; - Only direct cdr-over-assq shape is counted.
;;; - Ordinary cdr list traversal and a single local bridge stay out of scope.
;; : (-> SourceFile (List CallFact) )
(def (alist-inline-assq-cdr-calls file)
  (filter alist-inline-assq-cdr-call?
          (source-file-calls file)))

;;; Parser call predicate:
;;; - The callee must be cdr.
;;; - At least one parser-owned argument string must contain an assq form.
;; : (-> CallFact Boolean )
(def (alist-inline-assq-cdr-call? call)
  (and (equal? (call-fact-callee call) "cdr")
       (ormap alist-inline-assq-argument?
              (call-fact-arguments call))))

;;; Argument predicate:
;;; - Parser arguments are compact strings here.
;;; - We match assq as a form head, not arbitrary prose.
;; : (-> CallArgument Boolean )
(def (alist-inline-assq-argument? argument)
  (and (string? argument)
       (or (string-contains argument "(assq ")
           (string-contains argument "(assq'"))))

;;; Details boundary:
;;; - Finding details stay JSON-shaped at the report edge.
;;; - Selectors expose the repeated call sites for direct repair.
;; : (-> (List CallFact) PolicyDetails )
(def (alist-access-details lookups)
  (hash (kind "repeated-inline-alist-lookup")
        (lookupCount (length lookups))
        (selectors (map call-fact-selector lookups))
        (callees ["assq" "cdr"])
        (repair "replace repeated inline (cdr (assq ...)) with a record/defstruct, typed profile accessor, or one named alist lookup helper")))


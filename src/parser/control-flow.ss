;;; -*- Gerbil -*-
;;; Parser-owned control-flow syntax fact extraction.

(import :gerbil/expander
        :parser/model
        :parser/support
        :parser/syntax)

(export control-flow-facts-from-form
        control-flow-quality-facets)
;; ConfigConstant
(def +protected-control-heads+ '(try with-catch))
;; ConfigConstant
(def +protected-handler-heads+ '(catch finally))
;;; Runtime boundary taxonomy:
;;; - These heads come from Gerbil runtime/control, runtime/thread, and gerbil-utils generator evidence.
;;; - Keep cleanup, continuation, actor, coroutine, and parameter semantics distinct for agent guidance.
;; ConfigConstant
(def +cleanup-control-heads+ '(dynamic-wind with-unwind-protect))
;; ConfigConstant
(def +continuation-control-heads+
  '(let/cc call/cc call-with-current-continuation
    continuation-capture ##continuation-capture ##continuation-graft))
;; String
(def +resource-scope-heads+
  '(parameterize
    call-with-input call-with-output
    call-with-input-file call-with-output-file
    call-with-input-string call-with-output-string
    with-input with-output))
;; ConfigConstant
(def +parameter-control-heads+ '(call-with-parameters make-parameter))
;; ConfigConstant
(def +builder-control-heads+ '(with-list-builder))
;; ConfigConstant
(def +actor-control-heads+
  '(spawn spawn/name spawn/group spawn-actor spawn-thread
    thread-start! thread-init! construct-actor-thread))
;; ConfigConstant
(def +coroutine-control-heads+
  '(yield cothread continue in-coroutine in-cothread in-cothread/peekable
    generating<-for-each generating<-cothread))
;; : (-> Relpath Form Datum (List ControlFlowFact) )
(def (control-flow-facts-from-form relpath form datum)
  (control-flow-facts-from-stx relpath form (form-caller-name datum)))
;; control-flow-facts-from-stxes
;;   : (-> Relpath (List ExprStx) String (List ControlFlowFact))
;;   | doc m%
;;       `control-flow-facts-from-stxes relpath exprs caller` appends
;;       control-flow facts collected from each expression syntax object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (control-flow-facts-from-stxes "src/core.ss" exprs "handler")
;;       ;; => control-flow facts
;;       ```
;;     %
(def (control-flow-facts-from-stxes relpath exprs caller)
  (apply append
         (map (cut control-flow-facts-from-stx relpath <> caller)
              exprs)))
;;; Boundary:
;;; - control-flow-facts-from-stx coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath ExprStx String (List ControlFlowFact) )
(def (control-flow-facts-from-stx relpath expr-stx caller)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (control-flow-facts-from-stxes relpath items caller))
       ((member head '(quote quasiquote syntax quote-syntax))
        '())
       ((metadata-head? head)
        '())
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
         ((member head '(defclass .defclass defgeneric .defgeneric)) '())
         (else
          (control-flow-facts-from-stxes relpath
                                         (stx-form-body-items expr-stx datum)
                                         (or (form-caller-name datum) caller)))))
       ((let-head? head)
        (append
         (if (named-let-stx? expr-stx head)
           [(named-let-control-flow-fact relpath expr-stx caller)]
           '())
         (control-flow-facts-from-let-binding-stxes relpath
                                                   (let-binding-stxes expr-stx head)
                                                   caller)
         (control-flow-facts-from-stxes relpath
                                        (let-body-stxes expr-stx head)
                                        caller)))
       ((control-flow-head? head)
        (cons (generic-control-flow-fact relpath expr-stx head caller)
              (control-flow-facts-from-stxes relpath (cdr items) caller)))
       ((eq? head 'match)
        (cons (match-control-flow-fact relpath expr-stx caller)
              (control-flow-facts-from-stxes relpath (match-body-stxes expr-stx) caller)))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       (else
        (control-flow-facts-from-stxes relpath (cdr items) caller))))))
;; control-flow-facts-from-let-binding-stxes
;;   : (-> Relpath (List Binding) String (List ControlFlowFact))
;;   | doc m%
;;       `control-flow-facts-from-let-binding-stxes relpath bindings caller`
;;       collects control-flow facts from the initializer expression of each let
;;       binding.
;;
;;       # Examples
;;
;;       ```scheme
;;       (control-flow-facts-from-let-binding-stxes "src/core.ss" bindings "handler")
;;       ;; => control-flow facts
;;       ```
;;     %
(def (control-flow-facts-from-let-binding-stxes relpath bindings caller)
  (apply append
         (map (cut control-flow-facts-from-let-binding-stx relpath <> caller)
              bindings)))
;; : (-> Relpath Binding String (List ControlFlowFact) )
(def (control-flow-facts-from-let-binding-stx relpath binding caller)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (control-flow-facts-from-stx relpath (cadr items) caller)
      '())))
;; : (-> ExprStx Head Boolean )
(def (named-let-stx? expr-stx head)
  (and (eq? head 'let)
       (let (items (stx-list-items expr-stx))
         (and (pair? (cdr items))
              (symbol? (syntax->datum (cadr items)))))))
;; : (-> Relpath ExprStx String Fact )
(def (named-let-control-flow-fact relpath expr-stx caller)
  (let* ((items (stx-list-items expr-stx))
         (name (datum->string (syntax->datum (cadr items))))
         (bindings (let-binding-stxes expr-stx 'let))
         (body (let-body-stxes expr-stx 'let))
         (loc (stx-source expr-stx)))
    (make-control-flow-fact name
                            "named-let"
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            "manual-loop"
                            caller
                            (length bindings)
                            (length body))))
;; : (-> Head Boolean )
(def (control-flow-head? head)
  (or (member head +protected-control-heads+)
      (member head +protected-handler-heads+)
      (member head +cleanup-control-heads+)
      (member head +continuation-control-heads+)
      (member head +resource-scope-heads+)
      (member head +parameter-control-heads+)
      (member head +builder-control-heads+)
      (member head +actor-control-heads+)
      (member head +coroutine-control-heads+)))
;;; Role taxonomy:
;;; - Existing roles stay stable for policy compatibility; new roles expose finer runtime boundaries.
;;; - Control-flow facets below carry the cross-cutting guidance terms used by search and comments.
;; : (-> Head String )
(def (control-flow-role head)
  (cond
   ((member head +protected-control-heads+) "protected-control")
   ((member head +protected-handler-heads+) "protected-handler")
   ((member head +cleanup-control-heads+) "cleanup-boundary")
   ((member head +continuation-control-heads+) "continuation-control")
   ((member head +resource-scope-heads+) "resource-scope")
   ((member head +parameter-control-heads+) "parameter-state")
   ((member head +builder-control-heads+) "builder-control")
   ((member head +actor-control-heads+) "actor-control")
   ((member head +coroutine-control-heads+) "coroutine-control")
   (else "control-flow")))

;;; Facet projection:
;;; - Convert precise parser roles into search/comment vocabulary without widening the fact struct.
;;; - Keep this expression-level filter so every facet remains visibly tied to one control-flow role.
;; : (-> ControlFlowFact (List QualityFacet) )
(def (control-flow-quality-facets fact)
  (dedupe
   (filter identity
           [(and (member (control-flow-fact-role fact)
                         '("protected-control" "cleanup-boundary"
                           "continuation-control" "resource-scope"
                           "parameter-state" "actor-control"
                           "coroutine-control"))
                 "runtime-control-boundary")
            (and (equal? (control-flow-fact-role fact) "cleanup-boundary")
                 "dynamic-cleanup-boundary")
            (and (equal? (control-flow-fact-role fact) "continuation-control")
                 "continuation-capture-boundary")
            (and (equal? (control-flow-fact-role fact) "actor-control")
                 "actor-continuation-diagnostics")
            (and (equal? (control-flow-fact-role fact) "coroutine-control")
                 "generator-control-inversion")
            (and (equal? (control-flow-fact-role fact) "parameter-state")
                 "parameter-state-boundary")
            (and (equal? (control-flow-fact-role fact) "resource-scope")
            "resource-lifecycle-boundary")
            (and (equal? (control-flow-fact-role fact) "builder-control")
                "builder-boundary")
            (and (equal? (control-flow-fact-role fact) "pattern-branch")
                "extensible-match-dsl")
            (and (equal? (control-flow-fact-role fact) "manual-loop")
                "manual-loop-driver")])))
;; : (-> Relpath ExprStx Head String Fact )
(def (generic-control-flow-fact relpath expr-stx head caller)
  (let* ((items (stx-list-items expr-stx))
         (loc (stx-source expr-stx)))
    (make-control-flow-fact (datum->string head)
                            (datum->string head)
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            (control-flow-role head)
                            caller
                            0
                            (length (cdr items)))))
;; : (-> Relpath ExprStx String Fact )
(def (match-control-flow-fact relpath expr-stx caller)
  (let* ((items (stx-list-items expr-stx))
         (loc (stx-source expr-stx)))
    (make-control-flow-fact "match"
                            "match"
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            "pattern-branch"
                            caller
                            0
                            (length (drop* items 2)))))

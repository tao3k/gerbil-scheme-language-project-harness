;;; -*- Gerbil -*-
;;; Parser-owned higher-order syntax fact extraction.

(import :gerbil/expander
        :parser/formals
        :parser/model
        :parser/support
        :parser/syntax)

(export higher-order-facts-from-form
        higher-order-quality-facets)
;;; Feature taxonomy:
;;; - This table is parser-owned evidence for gerbil-utils style, not a style-only keyword list.
;;; - Keep heads grouped by semantic role so guide/search can explain why an agent should study the sample.
;; (List HigherOrderFact)
(def +higher-order-heads+
  '(lambda case-lambda
    cut cute
    curry rcurry compose compose1 rcompose !> !!>
    funcall constantly iterate-function iterated-function
    fn defn %app
    stx-apply stx-call stx-lambda def-stx defsyntax-stx defsyntax-stx/form
    generating<-for-each generating<-list generating<-vector
    generating-reverse<-vector generating<-iter
    list<-generating vector<-generating
    generating-map generating-fold generating-partition
    generating<-cothread in-cothread in-cothread/peekable
    :peekable-iter peekable-iterator-peek peekable-iterator-next!
    for/fold for*/fold
    map filter filter-map append-map
    andmap ormap every any
    find list-index
    fold foldl foldr fold-left fold-right
    with-list-builder))
;; : (-> Relpath Form Datum (List HigherOrderFact) )
(def (higher-order-facts-from-form relpath form datum)
  (higher-order-facts-from-stx relpath form (form-caller-name datum)))
;;; Boundary:
;;; - higher-order-facts-from-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath Exprs String (List HigherOrderFact) )
(def (higher-order-facts-from-stxes relpath exprs caller)
  (apply append
         (map (cut higher-order-facts-from-stx relpath <> caller)
              exprs)))
;;; Boundary:
;;; - higher-order-facts-from-stx coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath ExprStx String (List HigherOrderFact) )
(def (higher-order-facts-from-stx relpath expr-stx caller)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (higher-order-facts-from-stxes relpath items caller))
       ((member head '(quote quasiquote syntax quote-syntax))
        '())
       ((metadata-head? head)
        '())
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
         ((member head '(defclass .defclass defgeneric .defgeneric)) '())
         (else
          (let (body-facts
                (higher-order-facts-from-stxes relpath
                                               (stx-form-body-items expr-stx datum)
                                               (or (form-caller-name datum) caller)))
            (if (member head +higher-order-heads+)
              (cons (higher-order-fact-from-stx relpath expr-stx head datum caller)
                    body-facts)
              body-facts)))))
       ((let-head? head)
        (append
         (higher-order-facts-from-let-binding-stxes relpath
                                                   (let-binding-stxes expr-stx head)
                                                   caller)
         (higher-order-facts-from-stxes relpath
                                        (let-body-stxes expr-stx head)
                                        caller)))
       ((eq? head 'lambda)
        (cons (higher-order-fact-from-stx relpath expr-stx head datum caller)
              (higher-order-facts-from-stxes relpath
                                             (lambda-body-stxes expr-stx)
                                             caller)))
       ((eq? head 'case-lambda)
        (cons (higher-order-fact-from-stx relpath expr-stx head datum caller)
              (higher-order-facts-from-stxes relpath
                                             (case-lambda-body-stxes expr-stx)
                                             caller)))
       ((eq? head 'match)
        (higher-order-facts-from-stxes relpath (match-body-stxes expr-stx) caller))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       (else
        (append
         (if (member head +higher-order-heads+)
           [(higher-order-fact-from-stx relpath expr-stx head datum caller)]
           '())
         (higher-order-facts-from-stxes relpath (cdr items) caller)))))))
;;; Boundary:
;;; - higher-order-facts-from-let-binding-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath (List Definition) String (List HigherOrderFact) )
(def (higher-order-facts-from-let-binding-stxes relpath bindings caller)
  (apply append
         (map (cut higher-order-facts-from-let-binding-stx relpath <> caller)
              bindings)))
;; : (-> Relpath Binding String (List HigherOrderFact) )
(def (higher-order-facts-from-let-binding-stx relpath binding caller)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (higher-order-facts-from-stx relpath (cadr items) caller)
      '())))
;; : (-> Relpath ExprStx Head Datum String (List HigherOrderFact) )
(def (higher-order-fact-from-stx relpath expr-stx head datum caller)
  (let (loc (stx-source expr-stx))
    (make-higher-order-fact (datum->string head)
                            (datum->string head)
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            (higher-order-role head)
                            (higher-order-operand-count head datum)
                            (higher-order-arities head datum)
                            (higher-order-formal-names head datum)
                            caller)))
;;; Role taxonomy:
;;; - Roles are the stable agent-facing vocabulary for advanced composition and syntax-helper evidence.
;;; - Add new runtime or utils idioms here before policy consumes them.
;; : (-> Head String )
(def (higher-order-role head)
  (cond
   ((eq? head 'lambda) "anonymous-function")
   ((eq? head 'case-lambda) "multi-arity-function")
   ((member head '(cut cute)) "partial-application")
   ((member head '(curry rcurry)) "function-curry")
   ((member head '(compose compose1 rcompose)) "function-composition")
   ((member head '(!> !!>)) "pipeline-composition")
   ((member head '(funcall constantly iterate-function iterated-function))
    "higher-order-combinator")
   ((member head '(fn defn %app)) "autocurry-semantics")
   ((member head '(stx-apply stx-call stx-lambda def-stx
                   defsyntax-stx defsyntax-stx/form))
    "syntax-helper-dsl")
   ((member head '(generating<-for-each generating<-list generating<-vector
                   generating-reverse<-vector generating<-iter
                   list<-generating vector<-generating generating-map
                   generating-fold generating-partition))
    "generator-transform")
   ((member head '(generating<-cothread in-cothread in-cothread/peekable))
    "generator-control-inversion")
   ((member head '(:peekable-iter peekable-iterator-peek
                   peekable-iterator-next!))
    "stateful-protocol-wrapper")
   ((member head '(for/fold for*/fold)) "loop-fold")
   ((eq? head 'map) "sequence-map")
   ((eq? head 'filter) "sequence-filter")
   ((eq? head 'filter-map) "sequence-filter-map")
   ((eq? head 'append-map) "sequence-append-map")
   ((member head '(andmap ormap every any)) "sequence-predicate")
   ((member head '(find list-index)) "sequence-search")
   ((member head '(fold foldl foldr fold-left fold-right)) "sequence-fold")
   ((eq? head 'with-list-builder) "list-builder")
   (else "higher-order-call")))

;;; Quality facets expose gerbil-utils-style expression composition as parser-owned evidence.
;; : (-> HigherOrderFact (List QualityFacet) )
(def (higher-order-quality-facets fact)
  (dedupe
   (filter identity
           [(and (member (higher-order-fact-role fact)
                         '("sequence-map" "sequence-filter" "sequence-filter-map"
                           "sequence-append-map" "sequence-predicate"
                           "sequence-search" "sequence-fold"))
                 "expression-level-composition")
            (and (member (higher-order-fact-role fact)
                         '("partial-application" "function-curry"
                           "function-composition" "pipeline-composition"
                           "higher-order-combinator"))
                 "combinator-composition")
            (and (member (higher-order-fact-role fact)
                         '("function-composition" "pipeline-composition"))
                 "multi-value-composition")
            (and (equal? (higher-order-fact-role fact) "autocurry-semantics")
                 "autocurry-application-semantics")
            (and (equal? (higher-order-fact-role fact) "anonymous-function")
                 "lambda-local-abstraction")
            (and (and (equal? (higher-order-fact-role fact) "anonymous-function")
                      (> (higher-order-fact-operand-count fact) 0))
                 "parameterized-transform")
            (and (equal? (higher-order-fact-role fact) "syntax-helper-dsl")
                 "syntax-helper-extraction")
            (and (member (higher-order-fact-role fact)
                         '("partial-application" "function-curry"))
                 "function-specialization-abstraction")
            (and (member (higher-order-fact-role fact)
                         '("function-composition" "pipeline-composition"))
                 "function-pipeline-abstraction")
            (and (member (higher-order-fact-role fact)
                         '("generator-transform" "generator-control-inversion"))
                 "generator-interface-duality")
            (and (equal? (higher-order-fact-role fact) "generator-control-inversion")
                 "continuation-or-coroutine-boundary")
            (and (equal? (higher-order-fact-role fact) "stateful-protocol-wrapper")
                 "stateful-protocol-wrapper")
            (and (equal? (higher-order-fact-role fact) "multi-arity-function")
                 "case-lambda-optimization-boundary")
            (and (equal? (higher-order-fact-role fact) "multi-arity-function")
                 "multi-arity-abstraction")
            (and (member (higher-order-fact-role fact)
                         '("loop-fold" "list-builder"))
                 "builder-or-fold-combinator")])))

;; : (-> Head Datum Integer )
(def (higher-order-operand-count head datum)
  (cond
   ((eq? head 'lambda) (length (lambda-formal-datums datum)))
   ((eq? head 'case-lambda) (length (case-lambda-clause-datums datum)))
   (else (length (safe-cdr datum)))))
;;; Boundary:
;;; - higher-order-arities composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Head Datum (List HigherOrderFact) )
(def (higher-order-arities head datum)
  (cond
   ((eq? head 'lambda) [(length (lambda-formal-datums datum))])
   ((eq? head 'case-lambda)
    (map (lambda (clause)
           (length (lambda-formals-from-clause clause)))
         (case-lambda-clause-datums datum)))
   (else '())))
;;; Boundary:
;;; - higher-order-formal-names composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Head Datum (List HigherOrderFact) )
(def (higher-order-formal-names head datum)
  (cond
   ((eq? head 'lambda)
    (map datum->string (lambda-formal-datums datum)))
   ((eq? head 'case-lambda)
    (dedupe
     (apply append
            (map (lambda (clause)
                   (map datum->string (lambda-formals-from-clause clause)))
                 (case-lambda-clause-datums datum)))))
   (else '())))
;; : (-> Datum Integer )
(def (lambda-formal-datums datum)
  (lambda-formals-from-datum (safe-cadr datum)))
;;; Boundary:
;;; - case-lambda-clause-datums composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum Integer )
(def (case-lambda-clause-datums datum)
  (filter pair? (safe-cdr datum)))
;; : (-> Clause LambdaFormalsFromClause )
(def (lambda-formals-from-clause clause)
  (lambda-formals-from-datum (if (pair? clause) (car clause) '())))
;; : (-> Formals LambdaFormalsFromDatum )
(def (lambda-formals-from-datum formals)
  (cond
   ((symbol? formals) [formals])
   ((pair? formals) (formal-tail-datums formals))
   (else '())))

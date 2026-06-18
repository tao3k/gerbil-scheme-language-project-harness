;;; -*- Gerbil -*-
;;; Native Gerbil syntax fact extraction.

(import :gerbil/expander
        :parser/formals
        :parser/imports
        :parser/model
        :parser/support
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 drop)
        (only-in :std/srfi/13 string-prefix?))

(export +definition-heads+
        +declarative-top-level-heads+
        definitions-from-form
        calls-from-form
        module-import-facts-from-form
        macro-facts-from-form
        binding-facts-from-form
        +macro-definition-heads+
        form-caller-name
        stx-form-body-items
        let-head?
        let-binding-stxes
        let-body-stxes
        lambda-body-stxes
        case-lambda-body-stxes
        match-body-stxes
        top-form-from
        declarative-top-form?
        module-refs
        export-symbols
        string-datums)
;; ConfigConstant
(def +definition-heads+
  '(def def* define define-values define-syntax
    defstruct defclass .defclass defsyntax defsyntax-for-match defrules defrule
    defsyntax-for-import defsyntax-for-export defsyntax-for-import-export
    defn def-stx defsyntax-stx defsyntax-stx/form
    defalias define-type defmethod .defmethod defgeneric .defgeneric defprotocol .defprotocol
    defcompile-method))
;; ConfigConstant
(def +macro-definition-heads+
  '(define-syntax defsyntax defsyntax-for-match defrules defrule
    defsyntax-for-import defsyntax-for-export defsyntax-for-import-export
    defsyntax-stx defsyntax-stx/form))
;; ConfigConstant
(def +non-call-heads+
  '(quote quasiquote syntax quote-syntax
    package package: prelude: namespace: import export include
    if begin begin0 lambda case-lambda
    let let* letrec let-values let*-values
    cond case and or when unless match
    syntax-case syntax-rules identifier-rules))
;; FFI forms declare native ABI surfaces at module load/compile time.
;; Their nested call facts are declarations, not executable effects.
(def +declarative-top-level-heads+
  '("declare" "c-declare" "c-define-type" "define-c-lambda"
    "begin-ffi" "begin-foreign" "c-define" "namespace"))
;;; Boundary:
;;; - definitions-from-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath Form Datum DefinitionsFromForm )
(def (definitions-from-form relpath form datum)
  (let ((head (car datum))
        (name-datums (definition-name-datums datum)))
    (map (lambda (name)
             (let* ((loc (stx-source form))
                  (start (source-start-line loc))
                  (end (source-end-line loc)))
             (make-definition (datum->string name) (symbol->string head)
                              relpath start end
                              (definition-formal-names datum name)
                              (definition-formal-arity datum name))))
         name-datums)))
;; : (-> Relpath Form Datum CallsFromForm )
(def (calls-from-form relpath form datum)
  (if (declarative-top-level-datum? datum)
    '()
    (calls-from-stx relpath form (form-caller-name datum) '())))
;; : (-> Datum Boolean )
(def (declarative-top-level-datum? datum)
  (declarative-top-level-head? (top-form-datum-head datum)))
;;; Boundary:
;;; - calls-from-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath Exprs String LocalTypes CallsFromStxes )
(def (calls-from-stxes relpath exprs caller local-types)
  (apply append (map (cut calls-from-stx relpath <> caller local-types) exprs)))
;;; Boundary:
;;; - calls-from-stx composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath ExprStx String LocalTypes CallsFromStx )
(def (calls-from-stx relpath expr-stx caller local-types)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (calls-from-stxes relpath items caller local-types))
       ((member head '(quote quasiquote syntax quote-syntax))
        '())
       ((metadata-head? head)
        (calls-from-stxes relpath (cdr items) caller local-types))
       ((eq? head '.def)
        (calls-from-stxes relpath
                          (if (>= (length items) 2)
                            (drop items 2)
                            '())
                          (or (form-caller-name datum) caller)
                          local-types))
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
         ((eq? head 'define-type)
          (calls-from-stxes relpath
                            (stx-form-body-items expr-stx datum)
                            (or (form-caller-name datum) caller)
                            local-types))
         ((member head '(defclass .defclass defgeneric .defgeneric)) '())
         (else
          (calls-from-stxes relpath
                            (stx-form-body-items expr-stx datum)
                            (or (form-caller-name datum) caller)
                            local-types))))
       ((let-head? head)
        (let* ((bindings (let-binding-datums datum))
               (body-local-types (let-body-local-types head bindings local-types)))
          (append
           (calls-from-let-binding-stxes relpath
                                         head
                                         (let-binding-stxes expr-stx head)
                                         caller
                                         local-types)
           (calls-from-stxes relpath
                             (let-body-stxes expr-stx head)
                             caller
                             body-local-types))))
       ((eq? head 'lambda)
        (calls-from-stxes relpath (lambda-body-stxes expr-stx) caller local-types))
       ((eq? head 'case-lambda)
        (calls-from-stxes relpath (case-lambda-body-stxes expr-stx) caller local-types))
       ((eq? head 'match)
        (calls-from-stxes relpath (match-body-stxes expr-stx) caller local-types))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       ((member head +non-call-heads+)
        (calls-from-stxes relpath (cdr items) caller local-types))
       (else
        (let* ((args (cdr items))
               (arg-datums (map syntax->datum args))
               (loc (stx-source expr-stx))
               (start (source-start-line loc))
               (end (source-end-line loc)))
          (cons (make-call-fact (datum->string head)
                                (length arg-datums)
                                relpath start end
                                (map datum->string arg-datums)
                                (map (cut argument-type-name <> local-types)
                                     arg-datums)
                                caller)
                (calls-from-stxes relpath args caller local-types))))))))
;; calls-from-let-binding-stxes
;;   : (-> Relpath Head (List BindingStx) String LocalTypes (List CallFact))
;;   | doc m%
;;       `calls-from-let-binding-stxes relpath head bindings caller local-types`
;;       collects call facts from let binding initializer expressions, threading
;;       local type bindings through sequential let forms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (calls-from-let-binding-stxes "src/core.ss" 'let* bindings "handler" local-types)
;;       ;; => call facts
;;       ```
;;     %
(def (calls-from-let-binding-stxes relpath head bindings caller local-types)
  (cond
   ((null? bindings) '())
   ((member head '(let* let*-values))
    (cdr
     (foldl (lambda (binding state)
              (let* ((env (car state))
                     (out (cdr state))
                     (binding-calls
                      (calls-from-let-binding-stx relpath binding caller env))
                     (type-binding (binding-type (syntax->datum binding) env))
                     (next-env (if type-binding (cons type-binding env) env)))
                (cons next-env (append out binding-calls))))
            (cons local-types '())
            bindings)))
   (else
    (apply append
           (map (cut calls-from-let-binding-stx relpath <> caller local-types)
                bindings)))))
;; : (-> Relpath Binding String LocalTypes CallsFromLetBindingStx )
(def (calls-from-let-binding-stx relpath binding caller local-types)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (calls-from-stx relpath (cadr items) caller local-types)
      '())))
;; macro-facts-from-form
;;   : (-> Relpath Form Datum (List MacroFact))
;;   | doc m%
;;       `macro-facts-from-form relpath form datum` extracts macro definition
;;       facts from macro forms and annotates them with source and quality
;;       evidence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (macro-facts-from-form "src/core.ss" form datum)
;;       ;; => macro facts
;;       ```
;;     %
(def (macro-facts-from-form relpath form datum)
  (let ((head (and (pair? datum) (car datum))))
    (if (member head +macro-definition-heads+)
      (map (lambda (name)
             (let (loc (stx-source form))
               (make-macro-fact (datum->string name)
                                (symbol->string head)
                                relpath
                                (source-start-line loc)
                                (source-end-line loc)
                                (macro-transformer-kind datum)
                                (macro-phase head)
                                (macro-pattern-count datum)
                                (macro-hygienic? datum)
                                (macro-quality-facets head datum))))
           (definition-name-datums datum))
      '())))
;; : (-> Relpath Form Datum BindingFactsFromForm )
(def (binding-facts-from-form relpath form datum)
  (let (head (and (pair? datum) (car datum)))
    (if (member head +macro-definition-heads+)
      (formal-binding-facts-from-form relpath form datum "macro-formal")
      (append (formal-binding-facts-from-form relpath form datum "formal")
              (binding-facts-from-stx relpath form (form-caller-name datum) '())))))
;; formal-binding-facts-from-form
;;   : (-> Relpath Form Datum String (List BindingFact))
;;   | doc m%
;;       `formal-binding-facts-from-form relpath form datum kind` extracts
;;       binding facts for function or macro formals.
;;
;;       # Examples
;;
;;       ```scheme
;;       (formal-binding-facts-from-form "src/core.ss" form datum "formal")
;;       ;; => binding facts
;;       ```
;;     %
(def (formal-binding-facts-from-form relpath form datum kind)
  (let (names (definition-name-datums datum))
    (if (pair? names)
      (let ((name (car names))
            (loc (stx-source form)))
        (map (lambda (formal)
               (make-binding-fact (datum->string formal)
                                  kind
                                  relpath
                                  (source-start-line loc)
                                  (source-end-line loc)
                                  (datum->string name)
                                  #f))
             (definition-formal-datums datum name)))
      '())))
;;; Boundary:
;;; - binding-facts-from-stx coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath ExprStx String LocalTypes BindingFactsFromStx )
(def (binding-facts-from-stx relpath expr-stx caller local-types)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (binding-facts-from-stxes relpath items caller local-types))
       ((member head '(quote quasiquote syntax quote-syntax))
        '())
       ((metadata-head? head)
        '())
       ((eq? head '.def)
        '())
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
         ((member head '(define-type defclass .defclass defgeneric .defgeneric)) '())
         (else
          (binding-facts-from-stxes relpath
                                    (stx-form-body-items expr-stx datum)
                                    (or (form-caller-name datum) caller)
                                    local-types))))
       ((let-head? head)
        (let* ((bindings (let-binding-datums datum))
               (binding-stxes (let-binding-stxes expr-stx head))
               (body-local-types (let-body-local-types head bindings local-types)))
          (append
           (let-binding-facts relpath head binding-stxes caller local-types)
           (binding-facts-from-stxes relpath
                                     (let-body-stxes expr-stx head)
                                     caller
                                     body-local-types))))
       ((eq? head 'lambda)
        (binding-facts-from-stxes relpath (lambda-body-stxes expr-stx) caller local-types))
       ((eq? head 'case-lambda)
        (binding-facts-from-stxes relpath (case-lambda-body-stxes expr-stx) caller local-types))
       ((eq? head 'match)
        (binding-facts-from-stxes relpath (match-body-stxes expr-stx) caller local-types))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       (else
        (binding-facts-from-stxes relpath (cdr items) caller local-types))))))
;; binding-facts-from-stxes
;;   : (-> Relpath (List ExprStx) String LocalTypes (List BindingFact))
;;   | doc m%
;;       `binding-facts-from-stxes relpath exprs caller local-types` appends
;;       binding facts collected from each expression syntax object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-facts-from-stxes "src/core.ss" exprs "handler" local-types)
;;       ;; => binding facts
;;       ```
;;     %
(def (binding-facts-from-stxes relpath exprs caller local-types)
  (apply append
         (map (cut binding-facts-from-stx relpath <> caller local-types)
              exprs)))
;; let-binding-facts
;;   : (-> Relpath Head (List BindingStx) String LocalTypes (List BindingFact))
;;   | doc m%
;;       `let-binding-facts relpath head binding-stxes caller local-types`
;;       walks let bindings in source order and threads sequential type
;;       bindings for `let*` forms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (let-binding-facts "src/core.ss" 'let* binding-stxes "handler" local-types)
;;       ;; => binding facts
;;       ```
;;     %
(def (let-binding-facts relpath head binding-stxes caller local-types)
  (let ((rest binding-stxes)
        (env local-types)
        (out '()))
    (while (pair? rest)
      (let* ((binding (car rest))
             (datum (syntax->datum binding))
             (type-binding (binding-type datum env))
             (next-env (if (and (member head '(let* let*-values)) type-binding)
                         (cons type-binding env)
                         env)))
        (set! out
          (append out
                  (binding-facts-from-binding relpath head binding caller env)))
        (set! env next-env)
        (set! rest (cdr rest))))
    out))
;; binding-facts-from-binding
;;   : (-> Relpath Head BindingStx String LocalTypes (List BindingFact))
;;   | doc m%
;;       `binding-facts-from-binding relpath head binding caller local-types`
;;       extracts binding facts for each name introduced by one binding form.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-facts-from-binding "src/core.ss" 'let binding "handler" local-types)
;;       ;; => binding facts
;;       ```
;;     %
(def (binding-facts-from-binding relpath head binding caller local-types)
  (let* ((datum (syntax->datum binding))
         (names (binding-name-datums datum))
         (value (binding-value-datum datum))
         (loc (stx-source binding)))
    (map (lambda (name)
           (make-binding-fact (datum->string name)
                              (symbol->string head)
                              relpath
                              (source-start-line loc)
                              (source-end-line loc)
                              (or caller "-")
                              (argument-type-name value local-types)))
         names)))
;; : (-> Datum LocalTypes TypeSpec )
(def (argument-type-name datum local-types)
  (or (literal-type-name datum)
      (and (symbol? datum)
           (let (found (assoc (datum->string datum) local-types))
             (and found (cdr found))))))
;; : (-> Datum TypeSpec )
(def (literal-type-name datum)
  (cond
   ((number? datum) "number")
   ((string? datum) "string")
   ((boolean? datum) "bool")
   ((char? datum) "char")
   (else #f)))
;; : (-> Datum FormCallerName )
(def (form-caller-name datum)
  (and (pair? datum)
       (let (names (definition-name-datums datum))
         (and (pair? names)
              (null? (cdr names))
              (datum->string (car names))))))
;; : (-> Datum Integer )
(def (form-body-datums datum)
  (let ((head (and (pair? datum) (car datum))))
    (cond
     ((member head +definition-heads+) (safe-cddr datum))
     (else [datum]))))
;; : (-> Head Boolean )
(def (let-head? head)
  (member head '(let let* letrec let-values let*-values)))
;; : (-> Expr Integer )
(def (let-body-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-cdddr expr))
     (else (safe-cddr expr)))))
;; : (-> Expr Integer )
(def (let-binding-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-caddr expr))
     ((and (eq? head 'let) (single-let-binding-datum? second))
      [second])
     (else second))))
;; : (-> ExprStx Head LetBindingStxes )
(def (let-binding-stxes expr-stx head)
  (let (items (stx-list-items expr-stx))
    (cond
     ((and (eq? head 'let)
           (pair? (cdr items))
           (symbol? (syntax->datum (cadr items))))
      (stx-list-items (list-safe-caddr items)))
     ((and (eq? head 'let)
           (pair? (cdr items))
           (single-let-binding-datum? (syntax->datum (cadr items))))
      [(cadr items)])
     (else
      (stx-list-items (list-safe-cadr items))))))
;; : (-> Datum Boolean )
(def (single-let-binding-datum? datum)
  (and (pair? datum)
       (symbol? (car datum))
       (pair? (cdr datum))))
;; : (-> ExprStx Head LetBodyStxes )
(def (let-body-stxes expr-stx head)
  (let (items (stx-list-items expr-stx))
    (cond
     ((and (eq? head 'let)
           (pair? (cdr items))
           (symbol? (syntax->datum (cadr items))))
      (if (>= (length items) 3)
        (drop items 3)
        '()))
     (else
      (if (>= (length items) 2)
        (drop items 2)
        '())))))
;; : (-> Form Datum Integer )
(def (stx-form-body-items form datum)
  (let (items (stx-list-items form))
    (if (and (pair? datum) (member (car datum) +definition-heads+))
      (if (>= (length items) 2)
        (drop items 2)
        '())
      [form])))
;; : (-> ExprStx LambdaBodyStxes )
(def (lambda-body-stxes expr-stx)
  (let (items (stx-list-items expr-stx))
    (if (>= (length items) 2)
      (drop items 2)
      '())))
;;; Boundary:
;;; - case-lambda-body-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ExprStx CaseLambdaBodyStxes )
(def (case-lambda-body-stxes expr-stx)
  (apply append
         (map clause-body-stxes
              (cdr (stx-list-items expr-stx)))))
;;; Boundary:
;;; - match-body-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ExprStx MatchBodyStxes )
(def (match-body-stxes expr-stx)
  (let (items (stx-list-items expr-stx))
    (append (if (pair? (cdr items)) [(cadr items)] '())
            (apply append
                   (map clause-body-stxes
                        (if (>= (length items) 2)
                          (drop items 2)
                          '()))))))
;; : (-> ClauseStx ClauseBodyStxes )
(def (clause-body-stxes clause-stx)
  (let (items (stx-list-items clause-stx))
    (if (>= (length items) 1)
      (drop items 1)
      '())))
;; let-body-local-types
;;   : (-> Head (List Binding) LocalTypes LocalTypes)
;;   | doc m%
;;       `let-body-local-types head bindings local-types` extends the local type
;;       environment for let bodies, preserving sequential semantics for `let*`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (let-body-local-types 'let* bindings local-types)
;;       ;; => local type environment
;;       ```
;;     %
(def (let-body-local-types head bindings local-types)
  (cond
   ((not (pair? bindings)) local-types)
   ((member head '(let* let*-values))
    (sequential-binding-type-env bindings local-types))
   (else
    (append (binding-types bindings local-types) local-types))))
;; binding-types
;;   : (-> (List Binding) LocalTypes (List TypeBinding))
;;   | doc m%
;;       `binding-types bindings local-types` extracts type bindings from let
;;       binding datums without applying sequential environment updates.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-types bindings local-types)
;;       ;; => type bindings
;;       ```
;;     %
(def (binding-types bindings local-types)
  (filter-map (cut binding-type <> local-types)
              (datum-list-items bindings)))
;; sequential-binding-type-env
;;   : (-> (List Binding) LocalTypes LocalTypes)
;;   | doc m%
;;       `sequential-binding-type-env bindings local-types` extends the local
;;       type environment one binding at a time for `let*`-style semantics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (sequential-binding-type-env bindings local-types)
;;       ;; => local type environment
;;       ```
;;     %
(def (sequential-binding-type-env bindings local-types)
  (foldl (lambda (binding env)
           (let (type-binding (binding-type binding env))
             (if type-binding (cons type-binding env) env)))
         local-types
         (datum-list-items bindings)))
;; : (-> Binding LocalTypes TypeSpec )
(def (binding-type binding local-types)
  (and (pair? binding)
       (symbol? (car binding))
       (pair? (cdr binding))
       (let (type-name (argument-type-name (cadr binding) local-types))
         (and type-name (cons (datum->string (car binding)) type-name)))))
;; binding-name-datums
;;   : (-> Binding (List Symbol))
;;   | doc m%
;;       `binding-name-datums binding` returns every symbol introduced by a
;;       binding pattern.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-name-datums '(x 1))
;;       ;; => (x)
;;       ```
;;     %
(def (binding-name-datums binding)
  (cond
   ((and (pair? binding) (symbol? (car binding))) [(car binding)])
   ((and (pair? binding) (pair? (car binding)))
    (filter symbol? (flatten (car binding))))
   (else '())))
;; : (-> Binding BindingValueDatum )
(def (binding-value-datum binding)
  (and (pair? binding) (pair? (cdr binding)) (cadr binding)))
;; : (-> Datum String )
(def (macro-transformer-kind datum)
  (cond
   ((tree-contains-symbol? datum 'syntax-rules) "syntax-rules")
   ((tree-contains-symbol? datum 'identifier-rules) "identifier-rules")
   ((tree-contains-symbol? datum 'syntax-case) "syntax-case")
   ((tree-contains-symbol? datum 'datum->syntax) "datum->syntax")
   ((tree-contains-symbol? datum 'lambda) "lambda-transformer")
   (else "macro-transformer")))
;; : (-> Head String )
(def (macro-phase head)
  (cond
   ((eq? head 'defsyntax-for-match) "match")
   ((eq? head 'defsyntax-for-import) "import")
   ((eq? head 'defsyntax-for-export) "export")
   ((eq? head 'defsyntax-for-import-export) "import-export")
   (else "syntax")))
;; : (-> Datum Integer )
(def (macro-pattern-count datum)
  (let (head (and (pair? datum) (car datum)))
    (cond
     ((eq? head 'defrule) 1)
     ((eq? head 'defrules) (max 0 (length (safe-cdddr datum))))
     ((tree-contains-symbol? datum 'syntax-rules)
      (max 0 (length (safe-cdddr (syntax-rules-datum datum)))))
     (else 0))))
;; syntax-rules-datum
;;   : (-> Datum Datum)
;;   | doc m%
;;       `syntax-rules-datum datum` finds the first nested `syntax-rules` form,
;;       or returns the empty list when none is present.
;;
;;       # Examples
;;
;;       ```scheme
;;       (syntax-rules-datum '(defrules f () ((_ x) x)))
;;       ;; => ()
;;       ```
;;     %
(def (syntax-rules-datum datum)
  (or (find (lambda (item)
              (and (pair? item) (eq? (car item) 'syntax-rules)))
            (flatten-with-pairs datum))
      '()))
;; : (-> Datum Boolean )
(def (macro-hygienic? datum)
  (let (head (and (pair? datum) (car datum)))
    (if (or (member head '(defrule defrules))
            (tree-contains-symbol? datum 'syntax-rules)
            (tree-contains-symbol? datum 'identifier-rules)
            (tree-contains-symbol? datum 'syntax-case)
            (tree-contains-symbol? datum 'quote-syntax)
            (tree-contains-symbol? datum 'datum->syntax)
            (tree-contains-symbol? datum 'syntax))
      #t
      #f)))

;;; Macro quality facets expose Gerbil-specific macro engineering evidence to policy/search without relying on prose heuristics.
;; : (-> Head Datum (List QualityFacet) )
(def (macro-quality-facets head datum)
  (unique
   (filter identity
           [(and (macro-hygienic? datum) "hygienic-macro")
            (and (member head '(defrule defrules)) "macro-sugar")
            (and (tree-contains-symbol? datum 'syntax-rules)
                 "syntax-rules-pattern")
            (and (tree-contains-symbol? datum 'identifier-rules)
                 "identifier-rules-pattern")
            (and (tree-contains-symbol? datum 'syntax-case)
                 "syntax-case-transformer")
            (and (tree-contains-symbol? datum 'datum->syntax)
                 "datum->syntax-witness")
            (and (or (tree-contains-symbol? datum 'syntax)
                     (tree-contains-symbol? datum 'quote-syntax))
                 "syntax-template-witness")
            (and (tree-contains-symbol? datum 'lambda)
                 "lambda-transformer")])))

;; : (-> Relpath Form Datum TopFormFrom )
(def (top-form-from relpath form datum)
  (let* ((head (top-form-datum-head datum))
         (loc (stx-source form)))
    (make-top-form (form-kind head) (datum->string head) relpath
                   (source-start-line loc) (source-end-line loc))))
;; : (-> TopForm Boolean )
(def (declarative-top-form? form)
  (equal? (top-form-kind form) "declarative"))
;; : (-> Datum Head )
(def (top-form-datum-head datum)
  (cond
   ((pair? datum) (car datum))
   ((symbol? datum) datum)
   (else #f)))
;; : (-> Head String )
(def (form-kind head)
  (cond
   ((eq? head 'package:) "package")
   ((eq? head 'prelude:) "prelude")
   ((eq? head 'namespace:) "namespace")
   ((eq? head 'import) "import")
   ((eq? head 'export) "export")
   ((eq? head 'include) "include")
   ((declarative-top-level-head? head) "declarative")
   ((member head +definition-heads+) "definition")
   (else "form")))
;; : (-> Head Boolean )
(def (declarative-top-level-head? head)
  (and head (member (datum->string head) +declarative-top-level-heads+)))
;; module-refs
;;   : (-> Datum (List String))
;;   | doc m%
;;       `module-refs datum` returns string and colon-prefixed symbol module
;;       references found in a datum tree.
;;
;;       # Examples
;;
;;       ```scheme
;;       (module-refs '(import :std/sugar "support.ss"))
;;       ;; => (":std/sugar" "support.ss")
;;       ```
;;     %
(def (module-refs datum)
  (unique
   (filter-map
    (lambda (item)
      (cond
       ((string? item) item)
       ((and (symbol? item) (string-prefix? ":" (symbol->string item)))
        (symbol->string item))
       (else #f)))
    (flatten datum))))
;; export-symbols
;;   : (-> Datum (List String))
;;   | doc m%
;;       `export-symbols datum` returns exported symbol names while skipping
;;       import/export adapter markers and module refs.
;;
;;       # Examples
;;
;;       ```scheme
;;       (export-symbols '(export foo (rename: bar baz)))
;;       ;; => ("foo" "bar" "baz")
;;       ```
;;     %
(def (export-symbols datum)
  (unique
   (filter-map
    (lambda (item)
      (and (symbol? item)
           (let (s (symbol->string item))
             (and (not (member s '("export" "import:" "except-out" "rename:" "phi:" "only-in")))
                  (not (string-prefix? ":" s))
                  s))))
    (flatten datum))))
;; string-datums
;;   : (-> Datum (List String))
;;   | doc m%
;;       `string-datums datum` returns every string datum found in a flattened
;;       datum tree.
;;
;;       # Examples
;;
;;       ```scheme
;;       (string-datums '(include "a.ss" "b.ss"))
;;       ;; => ("a.ss" "b.ss")
;;       ```
;;     %
(def (string-datums datum)
  (filter string? (flatten datum)))

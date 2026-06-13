;;; -*- Gerbil -*-
;;; Native Gerbil syntax fact extraction.

(import :gerbil/expander
        :parser/model
        :parser/support
        :std/srfi/13)

(export +definition-heads+
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
        formal-tail-datums
        top-form-from
        module-refs
        export-symbols
        string-datums)

(def +definition-heads+
  '(def def* define define-values define-syntax
    defstruct defclass .defclass defsyntax defsyntax-for-match defrules defrule
    defalias defmethod .defmethod defgeneric .defgeneric defprotocol .defprotocol
    defcompile-method))
(def +macro-definition-heads+
  '(define-syntax defsyntax defsyntax-for-match defrules defrule))
(def +non-call-heads+
  '(quote quasiquote syntax quote-syntax
    package package: prelude: namespace: import export include
    if begin begin0 lambda case-lambda
    let let* letrec let-values let*-values
    cond case and or when unless match
    syntax-case syntax-rules identifier-rules))

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

(def (calls-from-form relpath form datum)
  (calls-from-stx relpath form (form-caller-name datum) '()))

(def (calls-from-stxes relpath exprs caller local-types)
  (apply append (map (cut calls-from-stx relpath <> caller local-types) exprs)))

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
        '())
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
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

(def (calls-from-let-binding-stxes relpath head bindings caller local-types)
  (cond
   ((null? bindings) '())
   ((member head '(let* let*-values))
    (let lp ((rest bindings)
             (env local-types)
             (out '()))
      (match rest
        ([binding . more]
         (let* ((binding-calls
                 (calls-from-let-binding-stx relpath binding caller env))
                (type-binding (binding-type (syntax->datum binding) env))
                (next-env (if type-binding (cons type-binding env) env)))
           (lp more next-env (append out binding-calls))))
        (else out))))
   (else
    (apply append
           (map (cut calls-from-let-binding-stx relpath <> caller local-types)
                bindings)))))

(def (calls-from-let-binding-stx relpath binding caller local-types)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (calls-from-stx relpath (cadr items) caller local-types)
      '())))

(def (module-import-facts-from-form relpath form)
  (let (items (cdr (stx-list-items form)))
    (filter-map (cut module-import-fact-from-stx relpath <>) items)))

(def (module-import-fact-from-stx relpath item)
  (let* ((datum (syntax->datum item))
         (loc (stx-source item))
         (module (module-ref-from-import-datum datum))
         (modifier (import-modifier datum))
         (phase (import-phase datum))
         (symbols (import-symbols datum))
         (alias (import-alias datum)))
    (and module
         (make-module-import-fact module phase modifier alias symbols relpath
                                  (source-start-line loc)
                                  (source-end-line loc)))))

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
                                (macro-hygienic? datum))))
           (definition-name-datums datum))
      '())))

(def (binding-facts-from-form relpath form datum)
  (let (head (and (pair? datum) (car datum)))
    (if (member head +macro-definition-heads+)
      (formal-binding-facts-from-form relpath form datum "macro-formal")
      (append (formal-binding-facts-from-form relpath form datum "formal")
              (binding-facts-from-stx relpath form (form-caller-name datum) '())))))

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
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
         ((member head '(defclass .defclass defgeneric .defgeneric)) '())
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

(def (binding-facts-from-stxes relpath exprs caller local-types)
  (apply append
         (map (cut binding-facts-from-stx relpath <> caller local-types)
              exprs)))

(def (let-binding-facts relpath head binding-stxes caller local-types)
  (let lp ((rest binding-stxes)
           (env local-types)
           (out '()))
    (match rest
      ([binding . more]
       (let* ((datum (syntax->datum binding))
              (type-binding (binding-type datum env))
              (next-env (if (and (member head '(let* let*-values)) type-binding)
                          (cons type-binding env)
                          env)))
         (lp more next-env
             (append out
                     (binding-facts-from-binding relpath head binding caller env)))))
      (else out))))

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

(def (argument-type-name datum local-types)
  (or (literal-type-name datum)
      (and (symbol? datum)
           (let (found (assoc (datum->string datum) local-types))
             (and found (cdr found))))))

(def (literal-type-name datum)
  (cond
   ((number? datum) "number")
   ((string? datum) "string")
   ((boolean? datum) "bool")
   ((char? datum) "char")
   (else #f)))

(def (form-caller-name datum)
  (and (pair? datum)
       (let (names (definition-name-datums datum))
         (and (pair? names)
              (null? (cdr names))
              (datum->string (car names))))))

(def (form-body-datums datum)
  (let ((head (and (pair? datum) (car datum))))
    (cond
     ((member head +definition-heads+) (safe-cddr datum))
     (else [datum]))))

(def (let-head? head)
  (member head '(let let* letrec let-values let*-values)))

(def (let-body-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-cdddr expr))
     (else (safe-cddr expr)))))

(def (let-binding-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-caddr expr))
     (else second))))

(def (let-binding-stxes expr-stx head)
  (let (items (stx-list-items expr-stx))
    (cond
     ((and (eq? head 'let)
           (pair? (cdr items))
           (symbol? (syntax->datum (cadr items))))
      (stx-list-items (list-safe-caddr items)))
     (else
      (stx-list-items (list-safe-cadr items))))))

(def (let-body-stxes expr-stx head)
  (let (items (stx-list-items expr-stx))
    (cond
     ((and (eq? head 'let)
           (pair? (cdr items))
           (symbol? (syntax->datum (cadr items))))
      (drop* items 3))
     (else (drop* items 2)))))

(def (stx-form-body-items form datum)
  (let (items (stx-list-items form))
    (if (and (pair? datum) (member (car datum) +definition-heads+))
      (drop* items 2)
      [form])))

(def (lambda-body-stxes expr-stx)
  (drop* (stx-list-items expr-stx) 2))

(def (case-lambda-body-stxes expr-stx)
  (apply append
         (map clause-body-stxes
              (cdr (stx-list-items expr-stx)))))

(def (match-body-stxes expr-stx)
  (let (items (stx-list-items expr-stx))
    (append (if (pair? (cdr items)) [(cadr items)] '())
            (apply append
                   (map clause-body-stxes (drop* items 2))))))

(def (clause-body-stxes clause-stx)
  (drop* (stx-list-items clause-stx) 1))

(def (let-body-local-types head bindings local-types)
  (cond
   ((not (pair? bindings)) local-types)
   ((member head '(let* let*-values))
    (sequential-binding-type-env bindings local-types))
   (else
    (append (binding-types bindings local-types) local-types))))

(def (binding-types bindings local-types)
  (filter-map (cut binding-type <> local-types)
              (datum-list-items bindings)))

(def (sequential-binding-type-env bindings local-types)
  (let lp ((rest (datum-list-items bindings))
           (env local-types))
    (match rest
      ([binding . more]
       (let (type-binding (binding-type binding env))
         (lp more (if type-binding (cons type-binding env) env))))
      (else env))))

(def (binding-type binding local-types)
  (and (pair? binding)
       (symbol? (car binding))
       (pair? (cdr binding))
       (let (type-name (argument-type-name (cadr binding) local-types))
         (and type-name (cons (datum->string (car binding)) type-name)))))

(def (binding-name-datums binding)
  (cond
   ((and (pair? binding) (symbol? (car binding))) [(car binding)])
   ((and (pair? binding) (pair? (car binding)))
    (filter symbol? (flatten (car binding))))
   (else '())))

(def (binding-value-datum binding)
  (and (pair? binding) (pair? (cdr binding)) (cadr binding)))

(def (module-ref-from-import-datum datum)
  (cond
   ((string? datum) datum)
   ((and (symbol? datum) (module-ref-symbol? datum)) (symbol->string datum))
   ((pair? datum)
    (let (found (find module-ref-datum? (datum-list-items (cdr datum))))
      (and found (module-ref-datum? found))))
   (else #f)))

(def (module-ref-datum? datum)
  (cond
   ((string? datum) datum)
   ((and (symbol? datum) (module-ref-symbol? datum)) (symbol->string datum))
   (else #f)))

(def (module-ref-symbol? symbol)
  (string-prefix? ":" (symbol->string symbol)))

(def (import-modifier datum)
  (if (pair? datum)
    (datum->string (car datum))
    "direct"))

(def (import-phase datum)
  (if (and (pair? datum) (eq? (car datum) 'for-syntax))
    "syntax"
    "runtime"))

(def (import-symbols datum)
  (if (pair? datum)
    (dedupe
     (filter-map
      (lambda (item)
        (and (symbol? item)
             (not (import-control-symbol? item))
             (not (module-ref-symbol? item))
             (symbol->string item)))
      (flatten datum)))
    '()))

(def (import-control-symbol? symbol)
  (member (symbol->string symbol)
          '("for-syntax" "only-in" "except-in" "rename-in" "rename-out"
            "prefix-in" "prefix:" "rename:" "phi:" "import:" "except-out")))

(def (import-alias datum)
  (and (pair? datum)
       (member (car datum) '(rename-in rename-out prefix-in))
       (let (symbols (import-symbols datum))
         (and (pair? symbols) (car symbols)))))

(def (macro-transformer-kind datum)
  (cond
   ((tree-contains-symbol? datum 'syntax-rules) "syntax-rules")
   ((tree-contains-symbol? datum 'identifier-rules) "identifier-rules")
   ((tree-contains-symbol? datum 'syntax-case) "syntax-case")
   ((tree-contains-symbol? datum 'datum->syntax) "datum->syntax")
   ((tree-contains-symbol? datum 'lambda) "lambda-transformer")
   (else "macro-transformer")))

(def (macro-phase head)
  (if (eq? head 'defsyntax-for-match) "match" "syntax"))

(def (macro-pattern-count datum)
  (let (head (and (pair? datum) (car datum)))
    (cond
     ((eq? head 'defrule) 1)
     ((eq? head 'defrules) (max 0 (length (safe-cdddr datum))))
     ((tree-contains-symbol? datum 'syntax-rules)
      (max 0 (length (safe-cdddr (syntax-rules-datum datum)))))
     (else 0))))

(def (syntax-rules-datum datum)
  (let lp ((rest (flatten-with-pairs datum)))
    (match rest
      ([item . more]
       (if (and (pair? item) (eq? (car item) 'syntax-rules))
         item
         (lp more)))
      (else '()))))

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

(def (top-form-from relpath form datum)
  (let* ((head (and (pair? datum) (car datum)))
         (loc (stx-source form)))
    (make-top-form (form-kind head) (datum->string head) relpath
                   (source-start-line loc) (source-end-line loc))))

(def (form-kind head)
  (cond
   ((eq? head 'package:) "package")
   ((eq? head 'prelude:) "prelude")
   ((eq? head 'namespace:) "namespace")
   ((eq? head 'import) "import")
   ((eq? head 'export) "export")
   ((eq? head 'include) "include")
   ((member head +definition-heads+) "definition")
   (else "form")))

(def (definition-name-datums datum)
  (let ((head (car datum))
        (second (safe-cadr datum)))
    (cond
     ((member head '(def def* define))
      (cond
       ((symbol? second) [second])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     ((eq? head 'define-values)
      (if (list? second) (filter symbol? second) '()))
     ((eq? head 'defmethod)
      (cond
       ((symbol? second) [second])
       ((and (pair? second)
             (eq? (car second) '@method)
             (symbol? (safe-cadr second)))
        [(safe-cadr second)])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     ((member head '(defclass .defclass defgeneric .defgeneric
                     .defmethod defsyntax defsyntax-for-match defrules defrule))
      (cond
       ((symbol? second) [second])
       ((and (pair? second)
             (eq? (car second) '@method)
             (symbol? (safe-cadr second)))
        [(safe-cadr second)])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     ((symbol? second) [second])
     (else '()))))

(def (definition-formal-names datum name)
  (filter-map
   (lambda (formal)
     (and (symbol? formal) (datum->string formal)))
   (definition-formal-datums datum name)))

(def (definition-formal-arity datum name)
  (let (formals (definition-formal-datums datum name))
    (and formals (length formals))))

(def (definition-formal-datums datum name)
  (let ((head (car datum))
        (second (safe-cadr datum)))
    (cond
     ((member head '(def def* define defmethod .defmethod
                     defsyntax defsyntax-for-match defrule))
      (cond
       ((and (pair? second) (eq? (car second) name))
        (formal-tail-datums (cdr second)))
       (else '())))
     (else '()))))

(def (formal-tail-datums tail)
  (cond
   ((null? tail) '())
   ((symbol? tail) [tail])
   ((pair? tail)
    (let (head (car tail))
      (if (and (symbol? head) (not (eq? head '...)))
        (cons head (formal-tail-datums (cdr tail)))
        (formal-tail-datums (cdr tail)))))
   (else '())))

(def (module-refs datum)
  (dedupe
   (filter-map
    (lambda (item)
      (cond
       ((string? item) item)
       ((and (symbol? item) (string-prefix? ":" (symbol->string item)))
        (symbol->string item))
       (else #f)))
    (flatten datum))))

(def (export-symbols datum)
  (dedupe
   (filter-map
    (lambda (item)
      (and (symbol? item)
           (let (s (symbol->string item))
             (and (not (member s '("export" "import:" "except-out" "rename:" "phi:" "only-in")))
                  (not (string-prefix? ":" s))
                  s))))
    (flatten datum))))

(def (string-datums datum)
  (filter string? (flatten datum)))

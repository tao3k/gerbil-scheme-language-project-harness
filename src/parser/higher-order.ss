;;; -*- Gerbil -*-
;;; Parser-owned higher-order syntax fact extraction.

(import :gerbil/expander
        :parser/model
        :parser/support
        :parser/syntax)

(export higher-order-facts-from-form)

(def +higher-order-heads+
  '(lambda case-lambda
    cut cute
    for/fold for*/fold
    map filter
    fold foldl foldr fold-left fold-right))

(def (higher-order-facts-from-form relpath form datum)
  (higher-order-facts-from-stx relpath form (form-caller-name datum)))

(def (higher-order-facts-from-stxes relpath exprs caller)
  (apply append
         (map (cut higher-order-facts-from-stx relpath <> caller)
              exprs)))

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
          (higher-order-facts-from-stxes relpath
                                         (stx-form-body-items expr-stx datum)
                                         (or (form-caller-name datum) caller)))))
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

(def (higher-order-facts-from-let-binding-stxes relpath bindings caller)
  (apply append
         (map (cut higher-order-facts-from-let-binding-stx relpath <> caller)
              bindings)))

(def (higher-order-facts-from-let-binding-stx relpath binding caller)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (higher-order-facts-from-stx relpath (cadr items) caller)
      '())))

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

(def (higher-order-role head)
  (cond
   ((eq? head 'lambda) "anonymous-function")
   ((eq? head 'case-lambda) "multi-arity-function")
   ((member head '(cut cute)) "partial-application")
   ((member head '(for/fold for*/fold)) "loop-fold")
   ((eq? head 'map) "sequence-map")
   ((eq? head 'filter) "sequence-filter")
   ((member head '(fold foldl foldr fold-left fold-right)) "sequence-fold")
   (else "higher-order-call")))

(def (higher-order-operand-count head datum)
  (cond
   ((eq? head 'lambda) (length (lambda-formal-datums datum)))
   ((eq? head 'case-lambda) (length (case-lambda-clause-datums datum)))
   (else (length (safe-cdr datum)))))

(def (higher-order-arities head datum)
  (cond
   ((eq? head 'lambda) [(length (lambda-formal-datums datum))])
   ((eq? head 'case-lambda)
    (map (lambda (clause)
           (length (lambda-formals-from-clause clause)))
         (case-lambda-clause-datums datum)))
   (else '())))

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

(def (lambda-formal-datums datum)
  (lambda-formals-from-datum (safe-cadr datum)))

(def (case-lambda-clause-datums datum)
  (filter pair? (safe-cdr datum)))

(def (lambda-formals-from-clause clause)
  (lambda-formals-from-datum (if (pair? clause) (car clause) '())))

(def (lambda-formals-from-datum formals)
  (cond
   ((symbol? formals) [formals])
   ((pair? formals) (formal-tail-datums formals))
   (else '())))

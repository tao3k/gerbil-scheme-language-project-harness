;;; -*- Gerbil -*-
;;; Parser-owned control-flow syntax fact extraction.

(import :gerbil/expander
        :parser/model
        :parser/support
        :parser/syntax)

(export control-flow-facts-from-form)

(def (control-flow-facts-from-form relpath form datum)
  (control-flow-facts-from-stx relpath form (form-caller-name datum)))

(def (control-flow-facts-from-stxes relpath exprs caller)
  (apply append
         (map (cut control-flow-facts-from-stx relpath <> caller)
              exprs)))

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
       ((eq? head 'match)
        (control-flow-facts-from-stxes relpath (match-body-stxes expr-stx) caller))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       (else
        (control-flow-facts-from-stxes relpath (cdr items) caller))))))

(def (control-flow-facts-from-let-binding-stxes relpath bindings caller)
  (apply append
         (map (cut control-flow-facts-from-let-binding-stx relpath <> caller)
              bindings)))

(def (control-flow-facts-from-let-binding-stx relpath binding caller)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (control-flow-facts-from-stx relpath (cadr items) caller)
      '())))

(def (named-let-stx? expr-stx head)
  (and (eq? head 'let)
       (let (items (stx-list-items expr-stx))
         (and (pair? (cdr items))
              (symbol? (syntax->datum (cadr items)))))))

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

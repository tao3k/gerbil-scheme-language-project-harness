;;; -*- Gerbil -*-
(package: sample/mop)
(export define-model-class)

(def *model-class-table* (make-hash-table-eq))

;; define-model-class
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `define-model-class` is a generated class macro that mixes the MOP
;;       class descriptor, slot layout, mixin super slots, accessors, mutators,
;;       constructor metadata, predicate metadata, metaclass metadata, method
;;       binding, slot contracts, and default values in one syntax owner.
;;     %
(defsyntax (define-model-class stx)
  (let ((form (syntax->datum stx)))
    (if (and (pair? form) (pair? (cdr form)) (pair? (cddr form)))
      (let* ((name (cadr form))
             (slots (caddr form))
             (descriptor [name slots]))
        (hash-put! *model-class-table* name descriptor)
        #`(begin
            (def (make-model-record . values)
              (cons '#,name values))
            (def (model-record? value)
              (and (pair? value) (eq? (car value) '#,name)))
            (def (model-record-ref value slot)
              (list-ref (cdr value) slot))
            (def (model-record-set! value slot next)
              (set-car! (list-tail (cdr value) slot) next))
            (def (call-model-method value method . args)
              (apply error "unbound generated model method" value method args))))
      (error "bad define-model-class syntax"))))

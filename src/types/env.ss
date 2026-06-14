;;; -*- Gerbil -*-
;;; Type environment facts derived from parser-owned definitions.

(import :parser/facade
        :std/sugar
        :types/model
        :types/signatures)

(export make-type-binding
        type-binding-name
        type-binding-kind
        type-binding-type
        type-binding-formals
        type-binding-arity
        type-binding-path
        type-binding-selector
        make-type-param-binding
        type-param-binding-function-name
        type-param-binding-name
        type-param-binding-type
        type-param-binding-path
        type-param-binding-selector
        build-type-env
        build-type-env/signatures
        build-param-type-env
        build-param-type-env/signatures
        duplicate-type-bindings)
;; TypeBindingStruct
(defstruct type-binding (name kind type formals arity path selector))
;; TypeParamBindingStruct
(defstruct type-param-binding (function-name name type path selector))
;; TypeSpec <- ProjectIndex
(def (build-type-env index)
  (build-type-env/signatures index '()))
;;; Boundary:
;;; - build-type-env/signatures composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; TypeSpec <- ProjectIndex NativeSignatures
(def (build-type-env/signatures index signatures)
  (map (cut definition->type-binding <> signatures)
       (project-definitions index)))
;; TypeSpec <- ProjectIndex
(def (build-param-type-env index)
  (build-param-type-env/signatures index '()))
;;; Boundary:
;;; - build-param-type-env/signatures composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; TypeSpec <- ProjectIndex NativeSignatures
(def (build-param-type-env/signatures index signatures)
  (append-map (cut definition->param-type-bindings <> signatures)
              (project-definitions index)))
;; TypeSpec <- Definition NativeSignatures
(def (definition->type-binding defn signatures)
  (make-type-binding (definition-name defn)
                     (definition-kind defn)
                     (or (signature-type-for (definition-name defn) signatures)
                         (make-type-unknown))
                     (definition-formals defn)
                     (definition-arity defn)
                     (definition-path defn)
                     (definition-selector defn)))
;; (List BindingFact) <- Definition NativeSignatures
(def (definition->param-type-bindings defn signatures)
  (let (signature-type (signature-type-for (definition-name defn) signatures))
    (if signature-type
      (signature-formal-bindings defn signature-type)
      '())))
;; (List BindingFact) <- Definition SignatureType
(def (signature-formal-bindings defn signature-type)
  (let (formals (definition-formals defn))
    (case (type-kind signature-type)
      ((function)
       (let (params (type-params signature-type))
         (if (= (length formals) (length params))
           (param-bindings defn formals params)
           '())))
      ((function-variadic)
       (if (>= (length formals) (type-function-variadic-min-arity signature-type))
         (param-bindings defn
                         formals
                         (repeat-type (type-function-variadic-param signature-type)
                                      (length formals)))
         '()))
      (else '()))))
;;; Invariant:
;;; - param-bindings owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List BindingFact) <- Definition Formals ParamTypes
(def (param-bindings defn formals param-types)
  (filter-map
   (lambda (param)
     (let ((name (car param))
           (type (cdr param)))
       (and (useful-param-type? type)
            (make-type-param-binding (definition-name defn)
                                     name
                                     type
                                     (definition-path defn)
                                     (definition-selector defn)))))
   (map cons formals param-types)))
;; Boolean <- Type
(def (useful-param-type? type)
  (not (member (type-kind type) '(unknown any))))
;;; Invariant:
;;; - repeat-type owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; TypeSpec <- Type Integer
(def (repeat-type type count)
  (make-list count type))
;;; Invariant:
;;; - append-map owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- (YY <- XX) (List XX)
(def (append-map fn items)
  (foldr (lambda (item out) (append (fn item) out)) '() items))
;;; Boundary:
;;; - duplicate-type-bindings is a keyed fold over path/name/kind triples.
;;; - State keeps seen bindings and duplicate pairs separate for repair output.
;; (List BindingFact) <- (List Definition)
(def (duplicate-type-bindings bindings)
  (let (state
        (foldl (lambda (binding state)
                 (if (poo-method-type-binding? binding)
                   state
                   (let* ((seen (car state))
                          (dupes (cdr state))
                          (key (list (type-binding-path binding)
                                     (type-binding-name binding)
                                     (type-binding-kind binding)))
                          (prior (assoc key seen)))
                     (if prior
                       (cons seen (cons [binding (cdr prior)] dupes))
                       (cons (cons (cons key binding) seen) dupes)))))
               (cons '() '())
               bindings))
    (reverse (cdr state))))

;;; Boundary:
;;; - POO methods are overload/specializer entries under one generic, not duplicate definitions.
;;; - Keep duplicate type checks focused on owners where a same-name binding really shadows evidence.
;; Boolean <- TypeBinding
(def (poo-method-type-binding? binding)
  (member (type-binding-kind binding) '("defmethod" ".defmethod")))

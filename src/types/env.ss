;;; -*- Gerbil -*-
;;; Type environment facts derived from parser-owned definitions.

(import :parser/facade
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

(defstruct type-binding (name kind type formals arity path selector))
(defstruct type-param-binding (function-name name type path selector))

(def (build-type-env index)
  (build-type-env/signatures index '()))

(def (build-type-env/signatures index signatures)
  (map (cut definition->type-binding <> signatures)
       (project-definitions index)))

(def (build-param-type-env index)
  (build-param-type-env/signatures index '()))

(def (build-param-type-env/signatures index signatures)
  (append-map (cut definition->param-type-bindings <> signatures)
              (project-definitions index)))

(def (definition->type-binding defn signatures)
  (make-type-binding (definition-name defn)
                     (definition-kind defn)
                     (or (signature-type-for (definition-name defn) signatures)
                         (make-type-unknown))
                     (definition-formals defn)
                     (definition-arity defn)
                     (definition-path defn)
                     (definition-selector defn)))

(def (definition->param-type-bindings defn signatures)
  (let (signature-type (signature-type-for (definition-name defn) signatures))
    (if signature-type
      (signature-formal-bindings defn signature-type)
      '())))

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

(def (param-bindings defn formals param-types)
  (let lp ((names formals) (types param-types) (out '()))
    (cond
     ((or (null? names) (null? types)) (reverse out))
     ((useful-param-type? (car types))
      (lp (cdr names)
          (cdr types)
          (cons (make-type-param-binding (definition-name defn)
                                         (car names)
                                         (car types)
                                         (definition-path defn)
                                         (definition-selector defn))
                out)))
     (else (lp (cdr names) (cdr types) out)))))

(def (useful-param-type? type)
  (not (member (type-kind type) '(unknown any))))

(def (repeat-type type count)
  (let lp ((remaining count) (out '()))
    (if (<= remaining 0)
      (reverse out)
      (lp (- remaining 1) (cons type out)))))

(def (append-map fn items)
  (let lp ((rest items) (out '()))
    (match rest
      ([] (reverse out))
      ([item . more]
       (lp more (append-reverse (fn item) out))))))

(def (append-reverse items out)
  (let lp ((rest items) (acc out))
    (match rest
      ([] acc)
      ([item . more] (lp more (cons item acc))))))

(def (duplicate-type-bindings bindings)
  (let lp ((rest bindings) (seen '()) (dupes '()))
    (match rest
      ([] (reverse dupes))
      ([binding . more]
       (let* ((key (list (type-binding-path binding)
                         (type-binding-name binding)
                         (type-binding-kind binding)))
              (prior (assoc key seen)))
         (if prior
           (lp more seen (cons [binding (cdr prior)] dupes))
           (lp more (cons (cons key binding) seen) dupes)))))))

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
        build-type-env
        build-type-env/signatures
        duplicate-type-bindings)

(defstruct type-binding (name kind type formals arity path selector))

(def (build-type-env index)
  (build-type-env/signatures index '()))

(def (build-type-env/signatures index signatures)
  (map (cut definition->type-binding <> signatures)
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

(def (duplicate-type-bindings bindings)
  (let lp ((rest bindings) (seen '()) (dupes '()))
    (match rest
      ([] (reverse dupes))
      ([binding . more]
       (let* ((key (cons (type-binding-path binding) (type-binding-name binding)))
              (prior (assoc key seen)))
         (if prior
           (lp more seen (cons [binding (cdr prior)] dupes))
           (lp more (cons (cons key binding) seen) dupes)))))))

;;; -*- Gerbil -*-
;;; Type environment facts derived from parser-owned definitions.

(import :parser)

(export make-type-binding
        type-binding-name
        type-binding-kind
        type-binding-type
        type-binding-formals
        type-binding-arity
        type-binding-path
        type-binding-selector
        build-type-env
        duplicate-type-bindings)

(defstruct type-binding (name kind type formals arity path selector))

(def (build-type-env index)
  (map definition->type-binding (project-definitions index)))

(def (definition->type-binding defn)
  (make-type-binding (definition-name defn)
                     (definition-kind defn)
                     "unknown"
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

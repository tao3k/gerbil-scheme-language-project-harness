;;; -*- Gerbil -*-
;;; Native type representation for Gerbil type facts.

(import :support/list)

(export make-type-unknown
        make-type-any
        make-type-base
        make-type-function
        type-kind
        type-name
        type-params
        type-result
        type=?
        type->string
        parse-type-sexpr)

(defstruct type-spec (kind name params result))

(def (make-type-unknown)
  (make-type-spec 'unknown "unknown" '() #f))

(def (make-type-any)
  (make-type-spec 'any "any" '() #f))

(def (make-type-base name)
  (make-type-spec 'base (normalize-type-name name) '() #f))

(def (make-type-function params result)
  (make-type-spec 'function #f params result))

(def (type-kind type)
  (type-spec-kind type))

(def (type-name type)
  (type-spec-name type))

(def (type-params type)
  (type-spec-params type))

(def (type-result type)
  (type-spec-result type))

(def (type=? left right)
  (and (eq? (type-kind left) (type-kind right))
       (equal? (type-name left) (type-name right))
       (types=? (type-params left) (type-params right))
       (let ((left-result (type-result left))
             (right-result (type-result right)))
         (cond
          ((and left-result right-result) (type=? left-result right-result))
          ((or left-result right-result) #f)
          (else #t)))))

(def (type->string type)
  (case (type-kind type)
    ((unknown) "unknown")
    ((any) "any")
    ((base) (type-name type))
    ((function)
     (string-append "(function ("
                    (join (map type->string (type-params type)) " ")
                    ") "
                    (type->string (type-result type))
                    ")"))
    (else "unknown")))

(def (parse-type-sexpr sexpr)
  (cond
   ((eq? sexpr 'unknown) (make-type-unknown))
   ((eq? sexpr 'any) (make-type-any))
   ((symbol? sexpr) (make-type-base sexpr))
   ((string? sexpr) (make-type-base sexpr))
   ((and (pair? sexpr) (eq? (car sexpr) 'function))
    (let ((params (safe-cadr sexpr))
          (result (safe-caddr sexpr)))
      (make-type-function
       (map parse-type-sexpr (if (list? params) params '()))
       (if result (parse-type-sexpr result) (make-type-unknown)))))
   (else (make-type-unknown))))

(def (types=? left right)
  (cond
   ((and (null? left) (null? right)) #t)
   ((or (null? left) (null? right)) #f)
   (else
    (and (type=? (car left) (car right))
         (types=? (cdr left) (cdr right))))))

(def (normalize-type-name name)
  (cond
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else "unknown")))

(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

(def (safe-caddr obj)
  (and (pair? obj) (pair? (cdr obj)) (pair? (cddr obj)) (caddr obj)))

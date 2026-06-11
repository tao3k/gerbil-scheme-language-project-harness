;;; -*- Gerbil -*-
;;; Native type representation for Gerbil type facts.

(import :support/list)

(export make-type-unknown
        make-type-any
        make-type-base
        make-type-pair
        make-type-list
        make-type-vector
        make-type-function
        make-type-function-variadic
        make-type-union
        make-type-record
        type-kind
        type-name
        type-params
        type-result
        type-pair-car
        type-pair-cdr
        type-list-elem
        type-vector-elem
        type-function-variadic-param
        type-function-variadic-min-arity
        type-union-members
        type-record-fields
        type-record-required
        record-field-type
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

(def (make-type-pair car-type cdr-type)
  (make-type-spec 'pair #f [car-type cdr-type] #f))

(def (make-type-list elem-type)
  (make-type-spec 'list #f [elem-type] #f))

(def (make-type-vector elem-type)
  (make-type-spec 'vector #f [elem-type] #f))

(def (make-type-function params result)
  (make-type-spec 'function #f params result))

(def (make-type-function-variadic param result . maybe-min-arity)
  (make-type-spec 'function-variadic
                  (if (null? maybe-min-arity) 0 (car maybe-min-arity))
                  [param]
                  result))

(def (make-type-union members)
  (make-type-spec 'union #f members #f))

(def (make-type-record fields . maybe-required)
  (make-type-spec 'record
                  #f
                  (normalize-record-fields fields)
                  (if (null? maybe-required)
                    '()
                    (map normalize-field-name (car maybe-required)))))

(def (type-kind type)
  (type-spec-kind type))

(def (type-name type)
  (type-spec-name type))

(def (type-params type)
  (type-spec-params type))

(def (type-result type)
  (type-spec-result type))

(def (type-pair-car type)
  (first-param-or-unknown type))

(def (type-pair-cdr type)
  (second-param-or-unknown type))

(def (type-list-elem type)
  (first-param-or-unknown type))

(def (type-vector-elem type)
  (first-param-or-unknown type))

(def (type-function-variadic-param type)
  (first-param-or-unknown type))

(def (type-function-variadic-min-arity type)
  (type-name type))

(def (type-union-members type)
  (type-params type))

(def (type-record-fields type)
  (type-params type))

(def (type-record-required type)
  (or (type-result type) '()))

(def (record-field-type type field-name)
  (let (found (assoc (normalize-field-name field-name) (type-record-fields type)))
    (and found (cdr found))))

(def (type=? left right)
  (and (eq? (type-kind left) (type-kind right))
       (case (type-kind left)
         ((record)
          (and (same-string-set? (type-record-required left)
                                 (type-record-required right))
               (record-fields=? (type-record-fields left)
                                (type-record-fields right))))
         (else
          (and (equal? (type-name left) (type-name right))
               (types=? (type-params left) (type-params right))
               (type-results=? (type-result left) (type-result right)))))))

(def (type->string type)
  (case (type-kind type)
    ((unknown) "unknown")
    ((any) "any")
    ((base) (type-name type))
    ((pair)
     (string-append "(pair "
                    (type->string (type-pair-car type))
                    " "
                    (type->string (type-pair-cdr type))
                    ")"))
    ((list)
     (string-append "(list "
                    (type->string (type-list-elem type))
                    ")"))
    ((vector)
     (string-append "(vector "
                    (type->string (type-vector-elem type))
                    ")"))
    ((function)
     (string-append "(function ("
                    (join (map type->string (type-params type)) " ")
                    ") "
                    (type->string (type-result type))
                    ")"))
    ((function-variadic)
     (string-append "(function* "
                    (type->string (type-function-variadic-param type))
                    " "
                    (type->string (type-result type))
                    " "
                    (number->string (type-function-variadic-min-arity type))
                    ")"))
    ((union)
     (string-append "(union "
                    (join (map type->string (type-union-members type)) " ")
                    ")"))
    ((record)
     (string-append "(record ("
                    (join (map record-field->string (type-record-fields type)) " ")
                    ") ("
                    (join (type-record-required type) " ")
                    "))"))
    (else "unknown")))

(def (parse-type-sexpr sexpr)
  (cond
   ((eq? sexpr 'unknown) (make-type-unknown))
   ((eq? sexpr 'any) (make-type-any))
   ((symbol? sexpr) (make-type-base sexpr))
   ((string? sexpr) (make-type-base sexpr))
   ((pair? sexpr)
    (let (head (car sexpr))
      (cond
       ((type-head? head '("function" "Function" "->"))
        (let ((params (safe-cadr sexpr))
              (result (safe-caddr sexpr)))
          (make-type-function
           (map parse-type-sexpr (if (list? params) params '()))
           (if result (parse-type-sexpr result) (make-type-unknown)))))
       ((type-head? head '("function*" "Function*" "->*"))
        (make-type-function-variadic
         (parse-type-sexpr (or (safe-cadr sexpr) 'unknown))
         (parse-type-sexpr (or (safe-caddr sexpr) 'unknown))
         (or (safe-cadddr sexpr) 0)))
       ((type-head? head '("pair" "Pair"))
        (make-type-pair
         (parse-type-sexpr (or (safe-cadr sexpr) 'unknown))
         (parse-type-sexpr (or (safe-caddr sexpr) 'unknown))))
       ((type-head? head '("list" "List"))
        (make-type-list (parse-type-sexpr (or (safe-cadr sexpr) 'unknown))))
       ((type-head? head '("vector" "Vector"))
        (make-type-vector (parse-type-sexpr (or (safe-cadr sexpr) 'unknown))))
       ((type-head? head '("union" "Union" "U"))
        (make-type-union (map parse-type-sexpr (cdr sexpr))))
       ((type-head? head '("record" "Record"))
        (make-type-record (parse-record-fields (safe-cadr sexpr))
                          (parse-required-fields (safe-caddr sexpr))))
       (else (make-type-unknown)))))
   (else (make-type-unknown))))

(def (type-results=? left right)
  (cond
   ((and left right) (type=? left right))
   ((or left right) #f)
   (else #t)))

(def (types=? left right)
  (cond
   ((and (null? left) (null? right)) #t)
   ((or (null? left) (null? right)) #f)
   (else
    (and (type=? (car left) (car right))
         (types=? (cdr left) (cdr right))))))

(def (record-fields=? left right)
  (and (= (length left) (length right))
       (all? (lambda (field)
               (let (found (assoc (car field) right))
                 (and found (type=? (cdr field) (cdr found)))))
             left)))

(def (same-string-set? left right)
  (and (= (length left) (length right))
       (all? (lambda (item) (member item right)) left)))

(def (normalize-type-name name)
  (cond
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else "unknown")))

(def (normalize-field-name name)
  (strip-trailing-colon (normalize-type-name name)))

(def (normalize-record-fields fields)
  (filter-map-record-fields fields))

(def (parse-record-fields fields)
  (if (list? fields)
    (filter-map-record-fields fields)
    '()))

(def (parse-required-fields required)
  (if (list? required)
    (map normalize-field-name required)
    '()))

(def (parse-record-field field)
  (and (pair? field)
       (let ((name (normalize-field-name (car field)))
             (tail (cdr field)))
         (and name
              (if (type-spec? tail)
                (cons name tail)
                (cons name (parse-type-sexpr (record-field-type-sexpr field))))))))

(def (record-field-type-sexpr field)
  (cond
   ((and (pair? field) (pair? (cdr field))) (cadr field))
   ((pair? field) (cdr field))
   (else 'unknown)))

(def (filter-map-record-fields fields)
  (let lp ((rest fields) (out '()))
    (match rest
      ([] (reverse out))
      ([field . more]
       (let (parsed (parse-record-field field))
         (if parsed
           (lp more (cons parsed out))
           (lp more out)))))))

(def (record-field->string field)
  (string-append "("
                 (car field)
                 " "
                 (type->string (cdr field))
                 ")"))

(def (type-head? head names)
  (member (normalize-type-name head) names))

(def (first-param-or-unknown type)
  (let (params (type-params type))
    (if (pair? params) (car params) (make-type-unknown))))

(def (second-param-or-unknown type)
  (let (params (type-params type))
    (if (and (pair? params) (pair? (cdr params)))
      (cadr params)
      (make-type-unknown))))

(def (all? predicate items)
  (cond
   ((null? items) #t)
   ((predicate (car items)) (all? predicate (cdr items)))
   (else #f)))

(def (strip-trailing-colon text)
  (let (size (string-length text))
    (if (and (> size 0) (eq? (string-ref text (- size 1)) #\:))
      (substring text 0 (- size 1))
      text)))

(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

(def (safe-caddr obj)
  (and (pair? obj) (pair? (cdr obj)) (pair? (cddr obj)) (caddr obj)))

(def (safe-cadddr obj)
  (and (pair? obj)
       (pair? (cdr obj))
       (pair? (cddr obj))
       (pair? (cdddr obj))
       (cadddr obj)))

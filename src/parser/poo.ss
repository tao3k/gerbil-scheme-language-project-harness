;;; -*- Gerbil -*-
;;; POO-specific parser-owned syntax facts.

(import :gerbil/expander
        :parser/model
        :parser/support
        :std/srfi/13)

(export +poo-definition-heads+
        poo-form-facts-from-form)

(def +poo-definition-heads+
  '(defclass .defclass defmethod .defmethod defgeneric .defgeneric))

(def (poo-form-facts-from-form relpath form datum)
  (let ((head (and (pair? datum) (car datum))))
    (if (member head +poo-definition-heads+)
      (map (lambda (name)
             (let (loc (stx-source form))
               (make-poo-form-fact (datum->string name)
                                   (symbol->string head)
                                   relpath
                                   (source-start-line loc)
                                   (source-end-line loc)
                                   (poo-form-role head)
                                   (poo-form-generic head datum name)
                                   (poo-form-receiver datum)
                                   (poo-form-receiver-type datum)
                                   (poo-class-supers head datum)
                                   (poo-class-slots head datum)
                                   (poo-class-options head datum)
                                   (poo-form-specializers datum)
                                   (poo-form-specializer-types datum))))
           (definition-name-datums datum))
      '())))

(def (definition-name-datums datum)
  (let ((head (car datum))
        (second (safe-cadr datum)))
    (cond
     ((member head '(defmethod .defmethod defclass .defclass defgeneric .defgeneric))
      (cond
       ((symbol? second) [second])
       ((and (pair? second)
             (eq? (car second) '@method)
             (symbol? (safe-cadr second)))
        [(safe-cadr second)])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     (else '()))))

(def (poo-form-role head)
  (cond
   ((member head '(defclass .defclass)) "class")
   ((member head '(defmethod .defmethod)) "method")
   ((member head '(defgeneric .defgeneric)) "generic")
   (else "poo-form")))

(def (poo-form-generic head datum name)
  (cond
   ((member head '(defgeneric .defgeneric)) (datum->string name))
   ((member head '(defmethod .defmethod)) (poo-method-generic datum))
   (else #f)))

(def (poo-method-generic datum)
  (let (spec (safe-cadr datum))
    (cond
     ((symbol? spec) (datum->string spec))
     ((and (pair? spec)
           (eq? (car spec) '@method)
           (symbol? (safe-cadr spec)))
      (datum->string (safe-cadr spec)))
     ((and (pair? spec) (symbol? (car spec))) (datum->string (car spec)))
     (else #f))))

(def (poo-form-receiver datum)
  (let (receiver (car-or-false (poo-method-receiver-datums datum)))
    (and receiver
         (symbol? (car receiver))
         (datum->string (car receiver)))))

(def (poo-form-receiver-type datum)
  (let (receiver (car-or-false (poo-method-receiver-datums datum)))
    (and receiver
         (pair? (cdr receiver))
         (datum->string (cadr receiver)))))

(def (poo-form-specializers datum)
  (map poo-specializer-name (poo-method-receiver-datums datum)))

(def (poo-form-specializer-types datum)
  (filter-map poo-specializer-type (poo-method-receiver-datums datum)))

(def (poo-method-receiver-datums datum)
  (let (spec (safe-cadr datum))
    (cond
     ((and (pair? spec) (eq? (car spec) '@method))
      (map (lambda (type) (list #f type))
           (datum-list-items (safe-cddr spec))))
     ((pair? spec)
      (filter poo-method-receiver-datum? (datum-list-items (cdr spec))))
     (else '()))))

(def (poo-method-receiver-datum? datum)
  (and (pair? datum) (symbol? (car datum))))

(def (poo-specializer-name receiver)
  (let ((name (safe-cadr receiver))
        (binding (car-or-false receiver)))
    (cond
     ((and binding name)
      (string-append (datum->string binding) ":" (datum->string name)))
     (name (datum->string name))
     (else ""))))

(def (poo-specializer-type receiver)
  (and (pair? (cdr receiver))
       (datum->string (cadr receiver))))

(def (car-or-false items)
  (and (pair? items) (car items)))

(def (poo-class-supers head datum)
  (if (member head '(defclass .defclass))
    (let (spec (safe-cadr datum))
      (if (and (pair? spec) (symbol? (car spec)))
        (map datum->string (datum-list-items (cdr spec)))
        '()))
    '()))

(def (poo-class-slots head datum)
  (if (member head '(defclass .defclass))
    (filter-map poo-slot-name (datum-list-items (safe-caddr datum)))
    '()))

(def (poo-slot-name datum)
  (cond
   ((symbol? datum) (datum->string datum))
   ((and (pair? datum) (symbol? (car datum))) (datum->string (car datum)))
   (else #f)))

(def (poo-class-options head datum)
  (if (member head '(defclass .defclass))
    (keyword-like-symbols (safe-cdddr datum))
    '()))

(def (keyword-like-symbols datum)
  (dedupe
   (filter-map (lambda (item)
                 (cond
                  ((keyword? item) (datum->string item))
                  ((symbol? item)
                   (let (text (symbol->string item))
                     (and (string-suffix? ":" text) text)))
                  (else #f)))
               (flatten datum))))

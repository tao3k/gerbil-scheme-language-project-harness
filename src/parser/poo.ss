;;; -*- Gerbil -*-
;;; POO-specific parser-owned syntax facts.

(import :gerbil/expander
        :parser/model
        :parser/support
        (only-in :std/srfi/13 string-suffix?))

(export +poo-definition-heads+
        poo-form-facts-from-form)
;; ConfigConstant
(def +poo-definition-heads+
  '(.def define-type defclass .defclass defmethod .defmethod defgeneric .defgeneric defprotocol .defprotocol))
;;; Boundary:
;;; - poo-form-facts-from-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PooFormFactsFromForm <- Relpath Form Datum
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
                                   (poo-form-supers head datum)
                                   (poo-form-slots head datum)
                                   (poo-form-options head datum)
                                   (poo-form-specializers datum)
                                   (poo-form-specializer-types datum))))
           (definition-name-datums datum))
      '())))
;; Integer <- Datum
(def (definition-name-datums datum)
  (let ((head (car datum))
        (second (safe-cadr datum)))
    (cond
     ((member head '(.def define-type defmethod .defmethod defclass .defclass defgeneric .defgeneric defprotocol .defprotocol))
      (cond
       ((symbol? second) [second])
       ((and (pair? second)
             (eq? (car second) '@method)
             (symbol? (safe-cadr second)))
        [(safe-cadr second)])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     (else '()))))
;; String <- Head
(def (poo-form-role head)
  (cond
   ((member head '(defclass .defclass)) "class")
   ((eq? head 'define-type) "type")
   ((eq? head '.def) "object")
   ((member head '(defmethod .defmethod)) "method")
   ((member head '(defgeneric .defgeneric)) "generic")
   ((member head '(defprotocol .defprotocol)) "protocol")
   (else "poo-form")))
;; PooFormGeneric <- Head Datum String
(def (poo-form-generic head datum name)
  (cond
   ((member head '(defgeneric .defgeneric)) (datum->string name))
   ((member head '(defmethod .defmethod)) (poo-method-generic datum))
   (else #f)))
;; PooMethodGeneric <- Datum
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
;; PooFormReceiver <- Datum
(def (poo-form-receiver datum)
  (let (receiver (car-or-false (poo-method-receiver-datums datum)))
    (and receiver
         (symbol? (car receiver))
         (datum->string (car receiver)))))
;; TypeSpec <- Datum
(def (poo-form-receiver-type datum)
  (let (receiver (car-or-false (poo-method-receiver-datums datum)))
    (and receiver
         (pair? (cdr receiver))
         (datum->string (cadr receiver)))))
;;; Boundary:
;;; - poo-form-specializers composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PooFormSpecializers <- Datum
(def (poo-form-specializers datum)
  (map poo-specializer-name (poo-method-receiver-datums datum)))
;;; Boundary:
;;; - poo-form-specializer-types composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; TypeSpec <- Datum
(def (poo-form-specializer-types datum)
  (filter-map poo-specializer-type (poo-method-receiver-datums datum)))
;;; Boundary:
;;; - poo-method-receiver-datums composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- Datum
(def (poo-method-receiver-datums datum)
  (let (spec (safe-cadr datum))
    (cond
     ((and (pair? spec) (eq? (car spec) '@method))
      (map (lambda (type) (list #f type))
           (datum-list-items (safe-cddr spec))))
     ((pair? spec)
      (filter poo-method-receiver-datum? (datum-list-items (cdr spec))))
     (else '()))))
;; Boolean <- Datum
(def (poo-method-receiver-datum? datum)
  (and (pair? datum) (symbol? (car datum))))
;; PooSpecializerName <- Receiver
(def (poo-specializer-name receiver)
  (let ((name (safe-cadr receiver))
        (binding (car-or-false receiver)))
    (cond
     ((and binding name)
      (string-append (datum->string binding) ":" (datum->string name)))
     (name (datum->string name))
     (else ""))))
;; TypeSpec <- Receiver
(def (poo-specializer-type receiver)
  (and (pair? (cdr receiver))
       (datum->string (cadr receiver))))
;; CarOrFalse <- (List XX)
(def (car-or-false items)
  (and (pair? items) (car items)))
;;; Boundary:
;;; - poo-form-supers composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PooFormSupers <- Head Datum
(def (poo-form-supers head datum)
  (cond
   ((member head '(defclass .defclass))
    (let (spec (safe-cadr datum))
      (if (and (pair? spec) (symbol? (car spec)))
        (map datum->string (datum-list-items (cdr spec)))
        '())))
   ((member head '(.def define-type))
    (poo-at-supers datum))
   (else '())))
;; (List String) <- Datum
(def (poo-at-supers datum)
  (let (spec (safe-cadr datum))
    (if (and (pair? spec) (symbol? (car spec)))
      (let (tail (member '@ (datum-list-items (cdr spec))))
        (if (and tail (pair? (cdr tail)))
          (poo-super-items (cadr tail))
          '()))
      '())))
;;; Invariant:
;;; - Bracket superclass syntax arrives as (@list ...).
;;; - Only that reader marker is stripped.
;;; - Ordinary list-shaped type names stay visible.
;;; - The map is safe because every remaining item is a superclass datum.
;; (List String) <- Datum
(def (poo-super-items datum)
  (cond
   ((symbol? datum) [(datum->string datum)])
   ((pair? datum)
    (let (items (datum-list-items datum))
      (map datum->string
           (if (and (pair? items) (eq? (car items) '@list))
             (cdr items)
             items))))
   (else '())))
;;; Boundary:
;;; - poo-form-slots composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PooFormSlots <- Head Datum
(def (poo-form-slots head datum)
  (cond
   ((member head '(defclass .defclass))
    (filter-map poo-slot-name (datum-list-items (safe-caddr datum))))
   ((eq? head 'define-type)
    (keyword-like-symbols (safe-cddr datum)))
   ((eq? head '.def)
    (map car (poo-object-slot-shapes datum)))
   (else '())))
;; PooSlotName <- Datum
(def (poo-slot-name datum)
  (cond
   ((symbol? datum) (datum->string datum))
   ((and (pair? datum) (symbol? (car datum))) (datum->string (car datum)))
   (else #f)))
;;; Intent:
;;; - Keep class/type/generic option projection declarative.
;;; - Filter/map expose which option namespaces are preserved without evaluating defaults.
;; (List String) <- Head Datum
(def (poo-form-options head datum)
  (cond
   ((member head '(defclass .defclass))
    (keyword-like-symbols (safe-cdddr datum)))
   ((eq? head 'define-type)
    (filter define-type-option? (keyword-like-symbols (safe-cddr datum))))
   ((member head '(defgeneric .defgeneric))
    (poo-generic-options datum))
   ((eq? head '.def)
    (map (lambda (shape)
           (string-append "slot:" (car shape) ":" (cdr shape)))
         (poo-object-slot-shapes datum)))
   (else '())))
;; Boolean <- String
(def (define-type-option? item)
  (member item '("sealed:" "transparent:" "slots:" "constructor:" "final:")))
;;; Boundary:
;;; - poo-generic-options preserves MOP dispatch options without evaluating defaults.
;;; - Keep data-flow evidence visible.
;; (List String) <- Datum
(def (poo-generic-options datum)
  (dedupe
   (poo-generic-options-from-items (datum-list-items (safe-cddr datum)))))
;;; Invariant:
;;; - Option values are skipped only for recognized POO generic keywords.
;;; - Unrecognized tokens continue scanning so parser facts stay permissive.
;; (List String) <- (List Datum)
(def (poo-generic-options-from-items items)
  (if (pair? items)
    (let* ((key (car items))
           (rest (cdr items))
           (value (and (pair? rest) (car rest)))
           (option (poo-generic-option key value))
           (tail (if option
                   (if (pair? rest) (cdr rest) '())
                   rest))
           (options (poo-generic-options-from-items tail)))
      (if option (cons option options) options))
    '()))
;; MaybeString <- Datum Datum
(def (poo-generic-option key value)
  (let (key-name (poo-option-key-name key))
    (and key-name
         (cond
          ((member key-name '("slot:" "from:"))
           (if value
             (string-append key-name (datum->string value))
             key-name))
          ((member key-name '("default:" "compute-default:"))
           key-name)
          (else #f)))))
;;; Boundary:
;;; - Slot extraction preserves declaration syntax without expanding POO.
;;; - Keyword slots consume their value; list and symbol slots consume one item.
;; (List (Pair String String)) <- Datum
(def (poo-object-slot-shapes datum)
  (dedupe
   (poo-object-slot-shapes-from-items (datum-list-items (safe-cddr datum)))))
;;; Invariant:
;;; - The scanner is permissive because fixtures include unusual slot syntax.
;;; - Recognized keyword slots consume their value.
;;; - Unknown tokens remain skippable.
;;; - The keyword lambda keeps slot-name binding local to the matching branch.
;; (List (Pair String String)) <- (List Datum)
(def (poo-object-slot-shapes-from-items items)
  (if (pair? items)
    (let (item (car items))
      (cond
       ((poo-keyword-slot-name item)
        => (lambda (name)
             (let* ((rest (cdr items))
                    (shape (poo-keyword-slot-shape name rest))
                    (tail (poo-keyword-slot-tail rest)))
               (cons shape (poo-object-slot-shapes-from-items tail)))))
       ((pair? item)
        (let ((shape (poo-list-slot-shape item))
              (shapes (poo-object-slot-shapes-from-items (cdr items))))
          (if shape (cons shape shapes) shapes)))
       ((symbol? item)
        (cons (cons (datum->string item) "lexical-constant")
              (poo-object-slot-shapes-from-items (cdr items))))
       (else (poo-object-slot-shapes-from-items (cdr items)))))
    '()))
;; MaybeString <- Datum
(def (poo-keyword-slot-name item)
  (let (key-name (poo-option-key-name item))
    (and key-name (poo-strip-slot-colon key-name))))
;; String <- String
(def (poo-strip-slot-colon text)
  (if (and (< 0 (string-length text))
           (string-suffix? ":" text))
    (substring text 0 (1- (string-length text)))
    text))
;; (Pair String String) <- String (List Datum)
(def (poo-keyword-slot-shape name rest)
  (cons name
        (cond
         ((not (pair? rest)) "missing-value")
         ((eq? (car rest) '?) "default")
         ((eq? (car rest) '=>) "inherited-computed")
         ((eq? (car rest) '=>.+) "mixin-override")
         (else "self-computed"))))
;; (List Datum) <- (List Datum)
(def (poo-keyword-slot-tail rest)
  (cond
   ((not (pair? rest)) '())
   ((member (car rest) '(? => =>.+))
    (if (pair? (cdr rest)) (cddr rest) '()))
   (else (cdr rest))))
;; MaybePair <- Datum
(def (poo-list-slot-shape spec)
  (let (name (poo-slot-name spec))
    (and name
         (cons name (poo-list-slot-kind (datum-list-items (cdr spec)))))))
;; String <- (List Datum)
(def (poo-list-slot-kind rest)
  (cond
   ((null? rest) "lexical-constant")
   ((eq? (car rest) '?) "default")
   ((eq? (car rest) '=>) "inherited-computed")
   ((eq? (car rest) '=>.+) "mixin-override")
   ((and (pair? (car rest))
         (eq? (caar rest) 'next-method))
    "inherited-computed")
   (else "self-computed")))
;;; Boundary:
;;; - keyword-like-symbols composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- Datum
(def (keyword-like-symbols datum)
  (dedupe
   (filter-map (lambda (item)
                 (poo-option-key-name item))
               (flatten datum))))
;; MaybeString <- Datum
(def (poo-option-key-name item)
  (cond
   ((keyword? item) (datum->string item))
   ((symbol? item)
    (let (text (symbol->string item))
      (and (string-suffix? ":" text) text)))
   (else #f)))

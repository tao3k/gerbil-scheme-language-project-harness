;;; -*- Gerbil -*-
;;; POO-specific parser-owned syntax facts.

(import :gerbil/expander
        :parser/model
        :parser/support
        (only-in :std/srfi/13 string-prefix? string-suffix?))

(export +poo-definition-heads+
        poo-form-facts-from-form)
;; ConfigConstant
(def +poo-definition-heads+
  '(.def define-type defclass .defclass defmethod .defmethod defgeneric .defgeneric defprotocol .defprotocol))

;; ConfigConstant
(def +poo-define-type-options+
  '("sealed:" "transparent:" "slots:" "constructor:" "final:"))

;; ConfigConstant
(def +poo-generic-value-options+
  '("slot:" "from:"))

;; ConfigConstant
(def +poo-generic-flag-options+
  '("default:" "compute-default:"))

;; ConfigConstant
(def +poo-runtime-hook-option-tokens+
  '((":pr" "hookFamily:poo-io" "runtimeHook:printer")
    (":wr" "hookFamily:poo-io" "runtimeHook:writeenv")
    (":json" "hookFamily:poo-io" "runtimeHook:json-read")
    (":write-json" "hookFamily:poo-io" "runtimeHook:json-write")))

;; ConfigConstant
(def +poo-slot-operator-kinds+
  '((? "default")
    (=> "inherited-computed")
    (=>.+ "mixin-override")))

;; ConfigConstant
(def +poo-inherited-slot-call-heads+
  '(next-method))

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
    (append (poo-generic-options datum)
            (poo-runtime-hook-options (poo-generic-name datum))))
   ((member head '(defmethod .defmethod))
    (poo-runtime-hook-options (poo-method-generic datum)))
   ((eq? head '.def)
    (map (lambda (shape)
           (string-append "slot:" (car shape) ":" (cdr shape)))
         (poo-object-slot-shapes datum)))
   (else '())))
;; Boolean <- String
(def (define-type-option? item)
  (member item +poo-define-type-options+))
;; MaybeString <- Datum
(def (poo-generic-name datum)
  (let (spec (safe-cadr datum))
    (cond
     ((symbol? spec) (datum->string spec))
     ((and (pair? spec) (symbol? (car spec))) (datum->string (car spec)))
     (else #f))))
;;; Boundary:
;;; - Runtime hook options are parser facts for protocol hooks, not policy whitelists.
;;; - Keep :pr/:wr/:json/:write-json visible to structural search and agent repair.
;; (List String) <- MaybeString
(def (poo-runtime-hook-options generic)
  (let (entry (and generic (assoc generic +poo-runtime-hook-option-tokens+)))
    (if entry (cdr entry) '())))
;;; Boundary:
;;; - poo-generic-options preserves MOP dispatch options without evaluating defaults.
;;; - Keep data-flow evidence visible.
;; (List String) <- Datum
(def (poo-generic-options datum)
  (poo-generic-options-with-default-dispatch
   (dedupe
    (poo-generic-options-from-items (datum-list-items (safe-cddr datum))))))
;;; Invariant:
;;; - Option values are skipped only for recognized POO generic keywords.
;;; - Unrecognized tokens continue scanning so parser facts stay permissive.
;; (List String) <- (List Datum)
(def (poo-generic-options-from-items items)
  (if (pair? items)
    (let* ((key (car items))
           (rest (cdr items))
           (value (and (pair? rest) (car rest)))
           (tokens (poo-generic-option-tokens key value))
           (tail (if (pair? tokens)
                   (if (pair? rest) (cdr rest) '())
                   rest))
           (options (poo-generic-options-from-items tail)))
      (if (pair? tokens) (append tokens options) options))
    '()))
;; (List String) <- Datum Datum
(def (poo-generic-option-tokens key value)
  (let (key-name (poo-option-key-name key))
    (if key-name
      (cond
       ((member key-name +poo-generic-value-options+)
        (poo-generic-value-option-tokens key-name value))
       ((member key-name +poo-generic-flag-options+)
        (poo-generic-flag-option-tokens key-name))
       (else '()))
      '())))
;; (List String) <- String Datum
(def (poo-generic-value-option-tokens key-name value)
  (let (raw (if value
              (string-append key-name (datum->string value))
              key-name))
    (cond
     ((equal? key-name "slot:")
      [raw (string-append "slotName:" (if value (datum->string value) ""))])
     ((equal? key-name "from:")
      [raw (string-append "dispatchSource:" (if value (datum->string value) ""))])
     (else [raw]))))
;; (List String) <- String
(def (poo-generic-flag-option-tokens key-name)
  (cond
   ((equal? key-name "default:") [key-name "defaultStrategy:default"])
   ((equal? key-name "compute-default:") [key-name "defaultStrategy:computed"])
   (else [key-name])))
;;; Intent:
;;; - Missing from: still carries the MOP default dispatch contract.
;;; - Emit it as parser evidence without evaluating the generic body or default.
;; (List String) <- (List String)
(def (poo-generic-options-with-default-dispatch options)
  (if (ormap (lambda (option)
               (string-prefix? "dispatchSource:" option))
             options)
    options
    (append options ["dispatchSource:instance"])))
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
         ((poo-slot-operator-kind (car rest)))
         (else "self-computed"))))
;; (List Datum) <- (List Datum)
(def (poo-keyword-slot-tail rest)
  (cond
   ((not (pair? rest)) '())
   ((poo-slot-operator-kind (car rest))
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
   ((poo-slot-operator-kind (car rest)))
   ((poo-inherited-slot-call? (car rest)) "inherited-computed")
   (else "self-computed")))

;; MaybeString <- Datum
(def (poo-slot-operator-kind item)
  (let (entry (assq item +poo-slot-operator-kinds+))
    (and entry (cadr entry))))

;; Bool <- Datum
(def (poo-inherited-slot-call? item)
  (and (pair? item)
       (member (car item) +poo-inherited-slot-call-heads+)))
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

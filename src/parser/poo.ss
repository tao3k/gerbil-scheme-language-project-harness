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
;; : (-> Relpath Form Datum PooFormFactsFromForm )
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
;; : (-> Datum Integer )
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
;; : (-> Head String )
(def (poo-form-role head)
  (cond
   ((member head '(defclass .defclass)) "class")
   ((eq? head 'define-type) "type")
   ((eq? head '.def) "object")
   ((member head '(defmethod .defmethod)) "method")
   ((member head '(defgeneric .defgeneric)) "generic")
   ((member head '(defprotocol .defprotocol)) "protocol")
   (else "poo-form")))
;; : (-> Head Datum String PooFormGeneric )
(def (poo-form-generic head datum name)
  (cond
   ((member head '(defgeneric .defgeneric)) (datum->string name))
   ((member head '(defmethod .defmethod)) (poo-method-generic datum))
   (else #f)))
;; : (-> Datum PooMethodGeneric )
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
;; : (-> Datum PooFormReceiver )
(def (poo-form-receiver datum)
  (let (receiver (car-or-false (poo-method-receiver-datums datum)))
    (and receiver
         (symbol? (car receiver))
         (datum->string (car receiver)))))
;; : (-> Datum TypeSpec )
(def (poo-form-receiver-type datum)
  (let (receiver (car-or-false (poo-method-receiver-datums datum)))
    (and receiver
         (pair? (cdr receiver))
         (datum->string (cadr receiver)))))
;;; Boundary:
;;; - poo-form-specializers composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum PooFormSpecializers )
(def (poo-form-specializers datum)
  (map poo-specializer-name (poo-method-receiver-datums datum)))
;;; Boundary:
;;; - poo-form-specializer-types composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum TypeSpec )
(def (poo-form-specializer-types datum)
  (filter-map poo-specializer-type (poo-method-receiver-datums datum)))
;;; Boundary:
;;; - poo-method-receiver-datums composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum Integer )
(def (poo-method-receiver-datums datum)
  (let (spec (safe-cadr datum))
    (cond
     ((and (pair? spec) (eq? (car spec) '@method))
      (map (lambda (type) (list #f type))
           (datum-list-items (safe-cddr spec))))
     ((pair? spec)
      (filter poo-method-receiver-datum? (datum-list-items (cdr spec))))
     (else '()))))
;; : (-> Datum Boolean )
(def (poo-method-receiver-datum? datum)
  (and (pair? datum) (symbol? (car datum))))
;; : (-> Receiver PooSpecializerName )
(def (poo-specializer-name receiver)
  (let ((name (safe-cadr receiver))
        (binding (car-or-false receiver)))
    (cond
     ((and binding name)
      (string-append (datum->string binding) ":" (datum->string name)))
     (name (datum->string name))
     (else ""))))
;; : (-> Receiver TypeSpec )
(def (poo-specializer-type receiver)
  (and (pair? (cdr receiver))
       (datum->string (cadr receiver))))
;; : (forall (a) (-> (List a) (Maybe a)) )
(def (car-or-false items)
  (and (pair? items) (car items)))
;;; Boundary:
;;; - poo-form-supers composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Head Datum PooFormSupers )
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
;; : (-> Datum (List String) )
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
;; : (-> Datum (List String) )
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
;; : (-> Head Datum PooFormSlots )
(def (poo-form-slots head datum)
  (cond
   ((member head '(defclass .defclass))
    (filter-map poo-slot-name (datum-list-items (safe-caddr datum))))
   ((eq? head 'define-type)
    (poo-define-type-slots datum))
   ((eq? head '.def)
    (map car (poo-object-slot-shapes datum)))
   (else '())))
;; : (-> Datum PooSlotName )
(def (poo-slot-name datum)
  (cond
   ((symbol? datum) (datum->string datum))
   ((and (pair? datum) (symbol? (car datum))) (datum->string (car datum)))
   (else #f)))
;;; Intent:
;;; - Keep class/type/generic option projection declarative.
;;; - Filter/map expose which option namespaces are preserved without evaluating defaults.
;; : (-> Head Datum (List String) )
(def (poo-form-options head datum)
  (cond
   ((member head '(defclass .defclass))
    (keyword-like-symbols (safe-cdddr datum)))
   ((eq? head 'define-type)
    (append
     (filter define-type-option? (keyword-like-symbols (safe-cddr datum)))
     (poo-define-type-method-options datum)))
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
;; : (-> String Boolean )
(def (define-type-option? item)
  (member item +poo-define-type-options+))

;;; Boundary:
;;; - define-type carries both declaration slots and method-table entries.
;;; - Method slots use dot-prefixed names in the spec or body keyword surface.
;;; - Type parameters such as `T` or `Value` remain out of method-slot evidence.
;; : (-> Datum (List String) )
(def (poo-define-type-slots datum)
  (dedupe
   (append
    (poo-define-type-header-method-slots datum)
    (poo-define-type-body-method-slots (safe-cddr datum)))))

;;; Boundary:
;;; - Header method-slot extraction only reads the define-type spec list.
;;; - Body labels are handled by the sibling scanner so slot provenance stays precise.
;; : (-> Datum (List String) )
(def (poo-define-type-header-method-slots datum)
  (let (spec (safe-cadr datum))
    (if (pair? spec)
      (filter-map poo-method-slot-name
                  (datum-list-items (cdr spec)))
      '())))

;;; Body labels such as `.map:` and `.ref:` are method-table slots.  Their
;;; following expression is parsed separately by poo-define-type-method-options.
;; : (-> (List Datum) (List String) )
(def (poo-define-type-body-method-slots items)
  (if (pair? items)
    (let (slot (poo-method-slot-name (car items)))
      (if slot
        (cons slot
              (poo-define-type-body-method-slots
               (if (pair? (cdr items)) (cddr items) '())))
        (poo-define-type-body-method-slots (cdr items))))
    '()))

;;; Method options expose Gerbil-POO method-table fluency without changing the
;;; public poo-form struct shape.  Search, guide, and policy can consume these
;;; stable string tokens as parser-owned evidence.
;; : (-> Datum (List String) )
(def (poo-define-type-method-options datum)
  (append
   (map (lambda (slot)
          (string-append "methodSlot:" slot))
        (poo-define-type-header-method-slots datum))
   (poo-define-type-body-method-options (safe-cddr datum))))

;; : (-> (List Datum) (List String) )
(def (poo-define-type-body-method-options items)
  (if (pair? items)
    (let ((slot (poo-method-slot-name (car items)))
          (rest (cdr items)))
      (if slot
        (let (value (and (pair? rest) (car rest)))
          (cons (string-append "methodSlot:" slot)
                (cons (string-append "methodBody:" slot ":"
                                     (poo-method-body-shape value))
                      (poo-define-type-body-method-options
                       (if (pair? rest) (cdr rest) '())))))
        (poo-define-type-body-method-options rest)))
    '()))

;; : (-> Datum MaybeString )
(def (poo-method-slot-name item)
  (let (key-name
        (cond
         ((symbol? item) (symbol->string item))
         ((keyword? item) (datum->string item))
         (else #f)))
    (and key-name
         (string-prefix? "." key-name)
         (poo-strip-slot-colon key-name))))

;;; Body shape classifies method implementations at the syntax level.  It never
;;; evaluates POO code; it only records whether a method is a lambda, partial
;;; application, selector call, pipeline, direct identifier, or ordinary call.
;; : (-> Datum String )
(def (poo-method-body-shape value)
  (cond
   ((symbol? value) "identifier")
   ((not (pair? value)) "literal")
   (else
    (let (head (car value))
      (cond
       ((eq? head 'lambda) "lambda")
       ((eq? head 'case-lambda) "case-lambda")
       ((member head '(cut cute)) "partial-application")
       ((member head '(curry rcurry)) "function-curry")
       ((member head '(compose compose1 rcompose)) "function-composition")
       ((member head '(!> !!>)) "pipeline-composition")
       ((member head '(fun fn defn %app)) "function-constructor")
       ((member head '(.@ .call @method)) "poo-selector-call")
       ((symbol? head) (string-append "call:" (symbol->string head)))
       (else "compound"))))))
;; : (-> Datum MaybeString )
(def (poo-generic-name datum)
  (let (spec (safe-cadr datum))
    (cond
     ((symbol? spec) (datum->string spec))
     ((and (pair? spec) (symbol? (car spec))) (datum->string (car spec)))
     (else #f))))
;;; Boundary:
;;; - Runtime hook options are parser facts for protocol hooks, not policy whitelists.
;;; - Keep :pr/:wr/:json/:write-json visible to structural search and agent repair.
;; : (-> MaybeString (List String) )
(def (poo-runtime-hook-options generic)
  (let (entry (and generic (assoc generic +poo-runtime-hook-option-tokens+)))
    (if entry (cdr entry) '())))
;;; Boundary:
;;; - poo-generic-options preserves MOP dispatch options without evaluating defaults.
;;; - Keep data-flow evidence visible.
;; : (-> Datum (List String) )
(def (poo-generic-options datum)
  (poo-generic-options-with-default-dispatch
   (dedupe
    (poo-generic-options-from-items (datum-list-items (safe-cddr datum))))))
;;; Invariant:
;;; - Option values are skipped only for recognized POO generic keywords.
;;; - Unrecognized tokens continue scanning so parser facts stay permissive.
;; : (-> (List Datum) (List String) )
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
;; : (-> Datum Datum (List String) )
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
;; : (-> String Datum (List String) )
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
;; : (-> String (List String) )
(def (poo-generic-flag-option-tokens key-name)
  (cond
   ((equal? key-name "default:") [key-name "defaultStrategy:default"])
   ((equal? key-name "compute-default:") [key-name "defaultStrategy:computed"])
   (else [key-name])))
;;; Intent:
;;; - Missing from: still carries the MOP default dispatch contract.
;;; - Emit it as parser evidence without evaluating the generic body or default.
;; : (-> (List String) (List String) )
(def (poo-generic-options-with-default-dispatch options)
  (if (ormap (lambda (option)
               (string-prefix? "dispatchSource:" option))
             options)
    options
    (append options ["dispatchSource:instance"])))
;;; Boundary:
;;; - Slot extraction preserves declaration syntax without expanding POO.
;;; - Keyword slots consume their value; list and symbol slots consume one item.
;; : (-> Datum (List (Pair String String)) )
(def (poo-object-slot-shapes datum)
  (dedupe
   (poo-object-slot-shapes-from-items (datum-list-items (safe-cddr datum)))))
;;; Invariant:
;;; - The scanner is permissive because fixtures include unusual slot syntax.
;;; - Recognized keyword slots consume their value.
;;; - Unknown tokens remain skippable.
;;; - The keyword lambda keeps slot-name binding local to the matching branch.
;; : (-> (List Datum) (List (Pair String String)) )
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
;; : (-> Datum MaybeString )
(def (poo-keyword-slot-name item)
  (let (key-name (poo-option-key-name item))
    (and key-name (poo-strip-slot-colon key-name))))
;; : (-> String String )
(def (poo-strip-slot-colon text)
  (if (and (< 0 (string-length text))
           (string-suffix? ":" text))
    (substring text 0 (1- (string-length text)))
    text))
;; : (-> String (List Datum) (Pair String String) )
(def (poo-keyword-slot-shape name rest)
  (cons name
        (cond
         ((not (pair? rest)) "missing-value")
         ((poo-slot-operator-kind (car rest)))
         (else "self-computed"))))
;; : (-> (List Datum) (List Datum) )
(def (poo-keyword-slot-tail rest)
  (cond
   ((not (pair? rest)) '())
   ((poo-slot-operator-kind (car rest))
    (if (pair? (cdr rest)) (cddr rest) '()))
   (else (cdr rest))))
;; : (-> Datum MaybePair )
(def (poo-list-slot-shape spec)
  (let (name (poo-slot-name spec))
    (and name
         (cons name (poo-list-slot-kind (datum-list-items (cdr spec)))))))
;; : (-> (List Datum) String )
(def (poo-list-slot-kind rest)
  (cond
   ((null? rest) "lexical-constant")
   ((poo-slot-operator-kind (car rest)))
   ((poo-inherited-slot-call? (car rest)) "inherited-computed")
   (else "self-computed")))

;; : (-> Datum MaybeString )
(def (poo-slot-operator-kind item)
  (let (entry (assq item +poo-slot-operator-kinds+))
    (and entry (cadr entry))))

;; : (-> Datum Bool )
(def (poo-inherited-slot-call? item)
  (and (pair? item)
       (member (car item) +poo-inherited-slot-call-heads+)))
;;; Boundary:
;;; - keyword-like-symbols composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum (List String) )
(def (keyword-like-symbols datum)
  (dedupe
   (filter-map (lambda (item)
                 (poo-option-key-name item))
               (flatten datum))))
;; : (-> Datum MaybeString )
(def (poo-option-key-name item)
  (cond
   ((keyword? item) (datum->string item))
   ((symbol? item)
    (let (text (symbol->string item))
      (and (string-suffix? ":" text) text)))
   (else #f)))

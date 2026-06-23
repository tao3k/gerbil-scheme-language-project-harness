;;; -*- Gerbil -*-
;;; Agent-facing POO policy checks.

(import :parser/facade
        :policy/agent-support
        :policy/model
        (only-in :std/srfi/13 string-contains string-join string-prefix?)
        (only-in :std/sugar filter filter-map hash ormap)
        :types/findings)

(export poo-direct-writeenv-findings
        poo-direct-writeenv-finding
        poo-io-runtime-witness-findings
        poo-io-runtime-witness-finding
        poo-object-model-findings
        poo-object-model-finding
        poo-method-shape-findings
        poo-method-shape-finding
        poo-prototype-fixed-point-findings
        poo-prototype-fixed-point-finding
        poo-construction-performance-findings
        poo-construction-performance-finding
        poo-clone-override-loop-performance-findings
        poo-clone-override-loop-performance-finding
        poo-materialization-loop-performance-findings
        poo-materialization-loop-performance-finding
        poo-composition-loop-performance-findings
        poo-composition-loop-performance-finding
        poo-validation-loop-performance-findings
        poo-validation-loop-performance-finding
        poo-lens-loop-performance-findings
        poo-lens-loop-performance-finding
        poo-object-construction-loop-performance-findings
        poo-object-construction-loop-performance-finding
        poo-type-construction-loop-performance-findings
        poo-type-construction-loop-performance-finding
        poo-debug-instrumentation-loop-performance-findings
        poo-debug-instrumentation-loop-performance-finding
        poo-slot-spec-mutation-loop-performance-findings
        poo-slot-spec-mutation-loop-performance-finding
        poo-slot-predicate-loop-performance-findings
        poo-slot-predicate-loop-performance-finding)
;; ConfigConstant
(def +manual-object-model-callees+
  '("hash" "make-hash-table" "list->hash-table"))
;; ConfigConstant
(def +poo-prototype-ref-callees+
  '(".ref" ".@" ".get"))
;; Integer
(def +poo-data-object-literal-min-slot-specs+ 12)
;; ConfigConstant
(def +poo-data-object-literal-callees+
  '(".o"))
;; ConfigConstant
(def +poo-clone-override-callees+
  '(".cc"))
;; ConfigConstant
(def +poo-materialization-callees+
  '(".alist"
    ".alist/sort"
    ".all-slots"
    ".all-slots/sort"
    ".refs/slots"
    "hash<-object"
    "force-object"))
;; ConfigConstant
(def +poo-composition-callees+
  '(".mix" ".extend" ".+"))
;; ConfigConstant
(def +poo-super-constructor-callees+
  '("object<-alist" "object<-hash" "object<-fun"))
;; ConfigConstant
(def +poo-validation-callees+
  '("validate" "element?" "monomorphic-object?"))
;; ConfigConstant
(def +poo-lens-modify-callees+
  '(".call" ".modify"))
;; ConfigConstant
(def +poo-object-constructor-callees+
  '("object<-alist" "object<-hash" "object<-fun" ".o" "make-object"))
;; ConfigConstant
(def +poo-type-constructor-callees+
  '("MonomorphicObject"))
;; ConfigConstant
(def +poo-debug-instrumentation-callees+
  '("trace-poo"))
;; ConfigConstant
(def +poo-slot-spec-mutation-callees+
  '(".def!" ".putslot!" ".setslot!"))
;; ConfigConstant
(def +poo-slot-predicate-callees+
  '("o?/slots"))
;;; Boundary:
;;; - poo-direct-writeenv-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-direct-writeenv-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (and (direct-writeenv-call? call)
                        (poo-direct-writeenv-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))
;; : (-> CallFact Boolean )
(def (direct-writeenv-call? call)
  (equal? (call-fact-callee call) "writeenv"))
;; : (-> SourceFile CallFact TypeFinding )
(def (poo-direct-writeenv-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-direct-writeenv-rule+)
   (policy-rule-severity +agent-poo-direct-writeenv-rule+)
   (source-file-path file)
   "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first"
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))
;;; Boundary:
;;; - poo-io-runtime-witness-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-io-runtime-witness-findings index)
  (filter-map
   (lambda (file)
     (and (index-source-runtime-file-path? index (source-file-path file))
          (poo-io-source-file? file)
          (poo-io-method-override-file? file)
          (poo-io-runtime-witness-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - poo-io-source-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (poo-io-source-file? file)
  (ormap poo-io-import? (source-file-imports file)))
;; : (-> String Boolean )
(def (poo-io-import? import)
  (or (equal? import ":clan/poo/io")
      (equal? import "clan/poo/io")
      (string-contains import "clan/poo/io")))
;;; Boundary:
;;; - poo-io-method-override-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (poo-io-method-override-file? file)
  (or (ormap (lambda (form)
               (member (top-form-head form)
                       ["defmethod" ".defmethod"]))
             (source-file-forms file))
      (ormap (lambda (call)
               (member (call-fact-callee call)
                       ["defmethod" ".defmethod"]))
             (source-file-calls file))))
;; : (-> SourceFile TypeFinding )
(def (poo-io-runtime-witness-finding file)
  (make-type-finding
   (policy-rule-id +agent-poo-io-runtime-witness-rule+)
   (policy-rule-severity +agent-poo-io-runtime-witness-rule+)
   (source-file-path file)
   "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified"
   (source-file-path file)
   (hash (next "search runtime-source writeenv printer hook")
         (requiredWitness "writeenv-roundtrip-witness"))))
;;; Boundary:
;;; - poo-object-model-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-object-model-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (filter-map
                   (lambda (call)
                     (and (manual-object-model-call? index file call)
                          (poo-object-model-finding file call)))
                   (source-file-calls file)))
                (project-index-files index)))
    '()))
;; : (-> ProjectIndex SourceFile CallFact Boolean )
(def (manual-object-model-call? index file call)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (null? (source-file-poo-forms file))
       (member (call-fact-callee call) +manual-object-model-callees+)
       (call-fact-caller call)
       (or (string-prefix? "make-" (call-fact-caller call))
           (string-prefix? "new-" (call-fact-caller call))
           (string-prefix? "build-" (call-fact-caller call)))))
;; : (-> SourceFile CallFact TypeFinding )
(def (poo-object-model-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-object-model-rule+)
   (policy-rule-severity +agent-poo-object-model-rule+)
   (source-file-path file)
   (string-append "manual object constructor " (call-fact-caller call)
                  " uses " (call-fact-callee call)
                  " while POO/protocol capability is active; prefer parser-owned defclass/defgeneric/defmethod or cite why a raw data record is intentional")
   (call-fact-selector call)
   (hash (constructor (call-fact-caller call))
         (callee (call-fact-callee call))
         (selector (call-fact-selector call))
         (next "search pattern poo class"))))
;;; Boundary:
;;; - Detect outer constructor projection bursts, not isolated slot reads.
;;; - POO best practice keeps inherited/defaulted slot fixed points in one
;;;   prototype with brace syntax, =>, =>.+, ?, and .mix.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-prototype-fixed-point-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (and (index-source-runtime-file-path? index (source-file-path file))
                           (null? (source-file-poo-forms file)))
                    (poo-prototype-fixed-point-file-findings file)
                    '()))
                (project-index-files index)))
    '()))
;;; Projection-burst transform:
;;; - Filter to POO slot projection calls first, then emit at most one finding
;;;   per constructor caller through first-call selection.
;;; - This keeps normal isolated `.ref` reads legal while making repeated
;;;   constructor projection visible as a prototype-shape repair.
;; : (-> SourceFile (List TypeFinding) )
(def (poo-prototype-fixed-point-file-findings file)
  (let (calls (filter poo-prototype-ref-call? (source-file-calls file)))
    (filter-map
     (lambda (call)
       (let (caller (call-fact-caller call))
         (and caller
              (poo-constructor-caller? caller)
              (first-poo-prototype-ref-call-for-caller? calls call)
              (let (count (poo-prototype-ref-call-count calls caller))
                (and (>= count 2)
                     (poo-prototype-fixed-point-finding file call count))))))
     calls)))
;; : (-> CallFact Boolean )
(def (poo-prototype-ref-call? call)
  (member (call-fact-callee call) +poo-prototype-ref-callees+))
;; : (-> String Boolean )
(def (poo-constructor-caller? caller)
  (or (string-prefix? "make-" caller)
      (string-prefix? "new-" caller)
      (string-prefix? "build-" caller)))
;; : (-> (List CallFact) CallFact Boolean )
(def (first-poo-prototype-ref-call-for-caller? calls target)
  (cond
   ((null? calls) #f)
   ((equal? (call-fact-caller (car calls)) (call-fact-caller target))
    (equal? (call-fact-selector (car calls)) (call-fact-selector target)))
   (else
    (first-poo-prototype-ref-call-for-caller? (cdr calls) target))))
;;; Projection count:
;;; - Count only calls that share the constructor caller already selected by
;;;   the burst detector.
;;; - Keeping the filter local makes the threshold evidence explicit in finding
;;;   details without building a separate grouping table.
;; : (-> (List CallFact) String Integer )
(def (poo-prototype-ref-call-count calls caller)
  (length
   (filter (lambda (call)
             (equal? (call-fact-caller call) caller))
           calls)))
;; : (-> SourceFile CallFact Integer TypeFinding )
(def (poo-prototype-fixed-point-finding file call count)
  (make-type-finding
   (policy-rule-id +agent-poo-prototype-fixed-point-rule+)
   (policy-rule-severity +agent-poo-prototype-fixed-point-rule+)
   (source-file-path file)
   (string-append
    "POO constructor " (call-fact-caller call)
    " projects " (number->string count)
    " slots with " (call-fact-callee call)
    "; prefer prototype-local composition with {(:: @ super) slot: ...}, =>, =>.+, ?, and .mix so the object fixed point stays in one POO shape")
   (call-fact-selector call)
   (hash (constructor (call-fact-caller call))
         (callee (call-fact-callee call))
         (projectionCount count)
         (guidanceMode "soft-warning")
         (trigger "constructor projection burst")
         (allowedUse "isolated .ref/.@/.get boundary reads are valid POO API usage")
         (repairShape "define a base prototype and refine slots inside {(:: @ super) ...}; use => for slot transforms, =>.+ for object merges, ? for defaults, and .mix for instance materialization")
         (docsPath "docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org")
         (source "gerbil-poo doc/poo.md:299-319, t/object-test.ss, and t/mop-test.ss")
         (preferredSyntax "{(:: @ super) slot: ...}, =>, =>.+, ?, .mix")
         (next "read docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org; gerbil-scheme-harness agent guide . --poo"))))
;;; Boundary:
;;; - This is a POO performance policy, not a build policy.
;;; - Large data-shaped `.o` calls can create avoidable macro-expansion work.
;;; - Small user-facing `.o` objects stay idiomatic and are not reported.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-construction-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (and (poo-large-data-object-literal-call? call)
                            (poo-construction-performance-finding file call)))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> CallFact Boolean )
(def (poo-large-data-object-literal-call? call)
  (and (member (call-fact-callee call) +poo-data-object-literal-callees+)
       (>= (poo-object-literal-slot-spec-count call)
           +poo-data-object-literal-min-slot-specs+)))

;; : (-> CallFact Integer )
(def (poo-object-literal-slot-spec-count call)
  (poo-object-literal-slot-spec-count/args (call-fact-arguments call)))

;; : (-> (List String) Integer )
(def (poo-object-literal-slot-spec-count/args args)
  (cond
   ((null? args) 0)
   ((poo-keyword-slot-argument? (car args))
    (+ 1
       (poo-object-literal-slot-spec-count/args
        (if (pair? (cdr args))
          (cddr args)
          (cdr args)))))
   (else
    (+ 1 (poo-object-literal-slot-spec-count/args (cdr args))))))

;; : (-> String Boolean )
(def (poo-keyword-slot-argument? arg)
  (and (> (string-length arg) 0)
       (char=? (string-ref arg (- (string-length arg) 1)) #\:)))

;; : (-> SourceFile CallFact TypeFinding )
(def (poo-construction-performance-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-construction-performance-rule+)
   (policy-rule-severity +agent-poo-construction-performance-rule+)
   (source-file-path file)
   (string-append
    "large data-shaped POO object construction uses " (call-fact-callee call)
    " with " (number->string (poo-object-literal-slot-spec-count call))
    " slot specs; prefer object<-alist for broad mostly-data values to reduce macro-expansion pressure while keeping public APIs POO-native")
   (call-fact-selector call)
   (hash (kind "poo-construction-performance")
         (constructor (or (call-fact-caller call) "top-level"))
         (callee (call-fact-callee call))
         (argumentCount (length (call-fact-arguments call)))
         (slotSpecCount (poo-object-literal-slot-spec-count call))
         (slotSpecThreshold +poo-data-object-literal-min-slot-specs+)
         (guidanceMode "performance-warning")
         (trigger "large data-shaped .o construction")
         (allowedUse "compact .o objects and user-facing prototypes remain idiomatic POO")
         (preferredConstruction "object<-alist for broad mostly-data POO values")
         (performanceEvidence "gerbil-poo .o expands every slot spec through object/slot-spec; measured large-object probes degrade sharply from 16-32 slot specs")
         (publicApiBoundary "keep public extension surfaces POO-native; optimize construction shape inside implementation modules")
         (sourceEvidence
          "poo-flow/docs/10-19-design/10.06-poo-module-system/39-gerbil-build-optimization-audit.org:50-60")
         (next "replace broad data-shaped .o construction with object<-alist or split meaningful fragments into named POO values"))))

;;; Boundary:
;;; - This catches repeated pure clone overrides in loop bodies.
;;; - A single `.cc` remains idiomatic; hot loops should not copy the full slot
;;;   list on every iteration when only one override changes.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-clone-override-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-clone-override-loop-driver file call))
                         (and loop
                              (poo-clone-override-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-clone-override-loop-driver file call)
  (and (member (call-fact-callee call) +poo-clone-override-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-call-loop-driver file call)
  (and (call-fact-caller call)
       (ormap (lambda (loop)
                (and (equal? (loop-driver-fact-caller loop)
                             (call-fact-caller call))
                     loop))
              (source-file-loop-driver-facts file))))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-clone-override-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-clone-override-loop-performance-rule+)
   (policy-rule-severity +agent-poo-clone-override-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly clones with " (call-fact-callee call)
    "; prefer accumulating scalar state and applying one final .cc, or use .put! only when mutation is intentional")
   (call-fact-selector call)
   (hash (kind "poo-clone-override-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated .cc clone override")
         (allowedUse "single .cc clone overrides and non-loop object refinement remain idiomatic POO")
         (preferredConstruction "accumulate loop state and apply one final .cc; use .put! only for intentional mutable objects")
         (performanceEvidence "gerbil-poo .cc copies the full slot list for each override; measured loop probes show .cc scales with slot count while .put! stays near constant")
         (sourceEvidence "gerbil-poo object.ss:462-494")
         (next "move .cc outside the loop or switch to an explicit stateful update boundary"))))

;;; Boundary:
;;; - This catches full-object materialization inside loop bodies.
;;; - Boundary serialization remains valid; hot loops should materialize once
;;;   or use direct slot access instead of walking/sorting every slot each pass.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-materialization-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-materialization-loop-driver file call))
                         (and loop
                              (poo-materialization-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-materialization-loop-driver file call)
  (and (member (call-fact-callee call) +poo-materialization-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-materialization-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-materialization-loop-performance-rule+)
   (policy-rule-severity +agent-poo-materialization-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly materializes object slots with " (call-fact-callee call)
    "; materialize once outside the loop or read only the required slots")
   (call-fact-selector call)
   (hash (kind "poo-materialization-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO materialization")
         (allowedUse "one-time boundary serialization and non-loop inspection remain valid POO usage")
         (preferredConstruction "materialize or project once outside the loop, or use direct .ref access for specific slots")
         (performanceEvidence "gerbil-poo .alist walks all slots, .alist/sort sorts them each call, force-object forces every slot, and .refs/slots maps selected slots; measured loop probes show materialize/project-once stays lower")
         (sourceEvidence "gerbil-poo object.ss:120-229")
         (next "hoist .alist/.alist/sort/.all-slots/.refs/slots/hash<-object/force-object out of the loop or narrow the loop to required scalar state"))))

;;; Boundary:
;;; - This catches POO composition chains built inside loop bodies.
;;; - One-time composition remains idiomatic; hot loops should accumulate scalar
;;;   state and apply the composition once at the boundary.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-composition-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-composition-loop-driver file call))
                         (and loop
                              (poo-composition-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-composition-loop-driver file call)
  (and (poo-composition-loop-call? call)
       (poo-call-loop-driver file call)))

;; : (-> CallFact Boolean )
(def (poo-composition-loop-call? call)
  (or (member (call-fact-callee call) +poo-composition-callees+)
      (and (member (call-fact-callee call) +poo-super-constructor-callees+)
           (poo-call-has-keyword-argument? call "supers:"))))

;; : (-> CallFact String Boolean )
(def (poo-call-has-keyword-argument? call keyword)
  (ormap (lambda (arg)
           (equal? arg keyword))
         (call-fact-arguments call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-composition-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-composition-loop-performance-rule+)
   (policy-rule-severity +agent-poo-composition-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly composes object supers with " (call-fact-callee call)
    "; accumulate loop state and compose the object once at the boundary")
   (call-fact-selector call)
   (hash (kind "poo-composition-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO composition")
         (allowedUse "one-time .mix/.extend/.+ composition and boundary object assembly remain idiomatic POO")
         (preferredConstruction "accumulate scalar loop state and apply one final POO composition outside the loop")
         (performanceEvidence "gerbil-poo composition creates new supers chains; first .ref computes precedence-list and slot-funs across supers")
         (sourceEvidence "gerbil-poo object.ss:47-95,160-180")
         (next "move .mix/.extend/.+/supers: object construction outside the loop or replace the loop state with scalar accumulation"))))

;;; Boundary:
;;; - This catches repeated POO/MOP validation over the same object shape inside
;;;   loop bodies.
;;; - Boundary validation remains valid; hot loops should consume an already
;;;   validated value or validate only changed scalar fields.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-validation-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-validation-loop-driver file call))
                         (and loop
                              (poo-validation-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-validation-loop-driver file call)
  (and (member (call-fact-callee call) +poo-validation-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-validation-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-validation-loop-performance-rule+)
   (policy-rule-severity +agent-poo-validation-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly validates object shape with " (call-fact-callee call)
    "; validate once before the loop or validate only changed scalar fields")
   (call-fact-selector call)
   (hash (kind "poo-validation-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO validation")
         (allowedUse "boundary validation and one-time type checks remain valid POO/MOP usage")
         (preferredConstruction "validate once outside the loop, then operate on the validated object or scalar fields")
         (performanceEvidence "gerbil-poo MonomorphicObject validation walks all object values; measured loop probes show validate-once stays near constant")
         (sourceEvidence "gerbil-poo mop.ss:80-230")
         (next "hoist validate/element? out of the loop or narrow the loop to direct .ref/scalar predicates"))))

;;; Boundary:
;;; - This catches Lens .modify inside loop bodies because slot-lens .set
;;;   delegates to `.cc`, which clones the POO object on every update.
;;; - Lens remains valid as a boundary abstraction; hot loops should carry
;;;   scalar state and apply one final object update.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-lens-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-lens-loop-driver file call))
                         (and loop
                              (poo-lens-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-lens-loop-driver file call)
  (and (poo-lens-modify-call? call)
       (poo-call-loop-driver file call)))

;; : (-> CallFact Boolean )
(def (poo-lens-modify-call? call)
  (or (and (equal? (call-fact-callee call) ".call")
           (poo-call-has-argument? call "Lens")
           (poo-call-has-argument? call ".modify"))
      (and (member (call-fact-callee call) +poo-lens-modify-callees+)
           (poo-call-has-argument? call "slot-lens"))))

;; : (-> CallFact String Boolean )
(def (poo-call-has-argument? call value)
  (ormap (lambda (arg)
           (equal? arg value))
         (call-fact-arguments call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-lens-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-lens-loop-performance-rule+)
   (policy-rule-severity +agent-poo-lens-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly updates through Lens .modify; slot-lens .set delegates to .cc, so each loop step can clone the full object")
   (call-fact-selector call)
   (hash (kind "poo-lens-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated Lens .modify over POO object")
         (allowedUse "one-time Lens .modify and non-loop lens composition remain valid POO/MOP usage")
         (preferredConstruction "accumulate scalar lens target state and apply one final .cc outside the loop")
         (performanceEvidence "gerbil-poo Lens .modify calls .set after .get, and slot-lens .set calls .cc; measured 2000 updates: 100 slots 1132ms, 500 slots 4489ms, scalar-final-.cc 0ms")
         (sourceEvidence "gerbil-poo mop.ss:424-484")
         (next "replace loop-local Lens .modify with direct .ref/scalar accumulation and a final .cc boundary update"))))

;;; Boundary:
;;; - This catches object construction from collection-like inputs inside loop
;;;   bodies.
;;; - Object construction remains valid at boundaries; hot loops should carry
;;;   scalar/list/hash state and build one POO object outside the loop.
;;; - If the same loop already has POO composition, R030 owns the repair to
;;;   avoid duplicate findings.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-object-construction-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-object-construction-loop-driver
                                   file call))
                         (and loop
                              (poo-object-construction-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-object-construction-loop-driver file call)
  (let (loop (poo-call-loop-driver file call))
    (and loop
         (poo-loop-local-object-constructor-call? call)
         (not (poo-loop-caller-has-composition-call? file call))
         loop)))

;; : (-> CallFact Boolean )
(def (poo-loop-local-object-constructor-call? call)
  (and (member (call-fact-callee call) +poo-object-constructor-callees+)
       (not (poo-call-has-keyword-argument? call "supers:"))
       (or (not (equal? (call-fact-callee call) ".o"))
           (< (poo-object-literal-slot-spec-count call)
              +poo-data-object-literal-min-slot-specs+))))

;; : (-> SourceFile CallFact Boolean )
(def (poo-loop-caller-has-composition-call? file target)
  (and (call-fact-caller target)
       (ormap (lambda (call)
                (and (not (equal? (call-fact-selector call)
                                  (call-fact-selector target)))
                     (equal? (call-fact-caller call)
                             (call-fact-caller target))
                     (poo-composition-loop-call? call)))
              (source-file-calls file))))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-object-construction-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-object-construction-loop-performance-rule+)
   (policy-rule-severity +agent-poo-object-construction-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly constructs objects with " (call-fact-callee call)
    "; hoist stable object construction or accumulate scalar/list/hash state and build one object at the boundary")
   (call-fact-selector call)
   (hash (kind "poo-object-construction-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO object construction")
         (allowedUse "boundary object construction and per-iteration construction with genuinely changing object shape remain valid POO usage")
         (preferredConstruction "hoist stable object construction or accumulate scalar/list/hash state and construct one final POO object")
         (performanceEvidence "gerbil-poo object<-alist/object<-hash allocate a new object shape; measured 2000 loop constructions: object<-alist 500 slots 4114ms, object<-hash 500 slots 9522ms, hoisted object 0ms")
         (sourceEvidence "gerbil-poo object.ss:136-151")
         (next "move object<-alist/object<-hash/object<-fun/.o construction outside the loop or return scalar/list/hash loop state and construct once"))))

;;; Boundary:
;;; - This catches loop-local construction of uncached POO/MOP type objects.
;;; - Type construction remains valid at module/boundary scope; hot loops
;;;   should reuse a named type object and then validate/check values.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-type-construction-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-type-construction-loop-driver
                                   file call))
                         (and loop
                              (poo-type-construction-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-type-construction-loop-driver file call)
  (and (member (call-fact-callee call) +poo-type-constructor-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-type-construction-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-type-construction-loop-performance-rule+)
   (policy-rule-severity +agent-poo-type-construction-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly constructs type objects with " (call-fact-callee call)
    "; hoist stable type construction to a named binding outside the loop")
   (call-fact-selector call)
   (hash (kind "poo-type-construction-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO/MOP type construction")
         (allowedUse "module-level and boundary type construction remain idiomatic POO/MOP usage")
         (preferredConstruction "hoist stable POO/MOP type objects to a named binding outside the loop")
         (performanceEvidence "gerbil-poo MonomorphicObject constructs a fresh type object with closure slots; measured 100000 loop constructions 6358ms, hoisted type object 67ms")
         (sourceEvidence "gerbil-poo mop.ss:188-208")
         (next "define the MonomorphicObject type once outside the loop, then reuse it for validation or projection"))))

;;; Boundary:
;;; - This catches loop-local debug instrumentation over POO objects.
;;; - trace-poo walks all slots and installs traced slot wrappers; it should be
;;;   a boundary/debug setup operation, not repeated hot-loop work.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-debug-instrumentation-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-debug-instrumentation-loop-driver
                                   file call))
                         (and loop
                              (poo-debug-instrumentation-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-debug-instrumentation-loop-driver file call)
  (and (member (call-fact-callee call) +poo-debug-instrumentation-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-debug-instrumentation-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-debug-instrumentation-loop-performance-rule+)
   (policy-rule-severity +agent-poo-debug-instrumentation-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly installs debug instrumentation with " (call-fact-callee call)
    "; trace the object once at a debug boundary and reuse the traced value")
   (call-fact-selector call)
   (hash (kind "poo-debug-instrumentation-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO debug instrumentation")
         (allowedUse "boundary trace-poo setup and one-off debugging remain valid POO diagnostics")
         (preferredConstruction "hoist trace-poo outside the loop and reuse the traced object")
         (performanceEvidence "gerbil-poo trace-poo walks .all-slots and installs traced wrappers; measured 500 slots x 50 constructions 2942ms, hoisted traced object 0ms")
         (sourceEvidence "gerbil-poo debug.ss:57-77")
         (next "move trace-poo to a debug setup boundary before the loop, or guard it behind a one-time diagnostic flag"))))

;;; Boundary:
;;; - This catches loop-local mutation of POO slot specifications.
;;; - Slot-spec mutation changes object shape; value updates should use .put!
;;;   when mutation is intentional, or pure loop state plus one boundary update.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-slot-spec-mutation-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-slot-spec-mutation-loop-driver
                                   file call))
                         (and loop
                              (poo-slot-spec-mutation-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-slot-spec-mutation-loop-driver file call)
  (and (member (call-fact-callee call) +poo-slot-spec-mutation-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-slot-spec-mutation-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-slot-spec-mutation-loop-performance-rule+)
   (policy-rule-severity +agent-poo-slot-spec-mutation-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly mutates slot specs with " (call-fact-callee call)
    "; keep slot definitions at setup boundaries and use .put! or scalar state for loop values")
   (call-fact-selector call)
   (hash (kind "poo-slot-spec-mutation-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO slot-spec mutation")
         (allowedUse "setup-time .def!/.putslot! shape definition remains valid POO usage")
         (preferredConstruction "define slots once at setup; use .put! for intentional value mutation or scalar loop state plus one final object update")
         (performanceEvidence "gerbil-poo .putslot! mutates object slot specs; measured .def! 500 slots x 5000 at 2020ms while .put! value updates stayed 0ms")
         (cacheEvidence "after object instantiation, .def! changes slot specs but existing cached values remain visible until cache reset")
         (sourceEvidence "gerbil-poo object.ss:424-450")
         (next "move .def!/.putslot!/.setslot! outside the loop; if changing only the value, use .put! for mutable objects or final .cc for pure updates"))))

;;; Boundary:
;;; - This catches loop-local construction/use of multi-slot POO predicates.
;;; - Single-slot .slot? checks stay valid; stable multi-slot shape predicates
;;;   should be hoisted when the object shape does not change in the loop.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-slot-predicate-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-slot-predicate-loop-driver file call))
                         (and loop
                              (poo-slot-predicate-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-slot-predicate-loop-driver file call)
  (and (member (call-fact-callee call) +poo-slot-predicate-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-slot-predicate-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-slot-predicate-loop-performance-rule+)
   (policy-rule-severity +agent-poo-slot-predicate-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly builds or applies a multi-slot predicate with " (call-fact-callee call)
    "; hoist the predicate result when object shape is stable")
   (call-fact-selector call)
   (hash (kind "poo-slot-predicate-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (loop-driver-fact-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO multi-slot predicate")
         (allowedUse "single .slot? checks and boundary o?/slots predicates remain valid POO usage")
         (preferredConstruction "hoist stable o?/slots predicate results outside the loop; hoist the predicate closure when only the slot list is stable")
         (performanceEvidence "gerbil-poo o?/slots maps .slot? across the slot list; measured 500 slots, 50 keys, 2000 loop checks 524ms, hoisted predicate result 0ms")
         (sourceEvidence "gerbil-poo object.ss:169-217")
         (next "move o?/slots outside the loop when the object shape is stable; keep loop state to changed values only"))))
;;; Boundary:
;;; - poo-method-shape-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-method-shape-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (fact)
                   (and (equal? (poo-form-fact-role fact) "method")
                        (let (missing (poo-method-shape-missing index fact))
                          (and (pair? missing)
                               (poo-method-shape-finding file fact missing)))))
                 (source-file-poo-forms file)))
              (project-index-files index))))
;;; Boundary:
;;; - poo-method-shape-missing composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Fact PooMethodShapeMissing )
(def (poo-method-shape-missing index fact)
  (filter identity
          [(and (blank-string? (poo-form-fact-generic fact)) "generic")
           (and (not (blank-string? (poo-form-fact-generic fact)))
                (not (poo-generic-fact-exists? index (poo-form-fact-generic fact)))
                "defgeneric")
           (and (blank-string? (poo-form-fact-receiver-type fact)) "receiver-type")
           (and (not (blank-string? (poo-form-fact-receiver-type fact)))
                (not (poo-receiver-evidence-exists?
                      index
                      (poo-form-fact-receiver-type fact)))
                "defclass-or-defprotocol")]))
;;; Boundary:
;;; - poo-generic-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Generic Boolean )
(def (poo-generic-fact-exists? index generic)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "generic")
          (equal? (poo-form-fact-generic fact) generic)))
   (project-poo-forms index)))
;; : (-> ProjectIndex String Boolean )
(def (poo-receiver-evidence-exists? index name)
  (or (poo-class-fact-exists? index name)
      (poo-protocol-fact-exists? index name)))
;; : (-> SourceFile Fact Missing TypeFinding )
(def (poo-method-shape-finding file fact missing)
  (make-type-finding
   (policy-rule-id +agent-poo-method-shape-rule+)
   (policy-rule-severity +agent-poo-method-shape-rule+)
   (source-file-path file)
   (string-append "POO method " (poo-form-fact-name fact)
                  " is missing parser-owned "
                  (string-join missing ",")
                  " facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")
   (poo-form-fact-selector fact)
   (hash (generic (or (poo-form-fact-generic fact) ""))
         (receiverType (or (poo-form-fact-receiver-type fact) ""))
         (missing missing)
         (next "search pattern poo class protocol"))))

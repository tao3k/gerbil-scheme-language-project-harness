;;; -*- Gerbil -*-
;;; Agent-facing policy checks over facade intent comments.

(import :gerbil/gambit
        :parser/facade
        :policy/model
        :policy/modularity
        :std/misc/ports
        :std/srfi/13
        :std/sugar
        :types/findings)

(export run-agent-policy
        facade-intent-finding
        generic-owner-segment
        generic-owner-finding
        vague-definition-finding
        top-level-executable-finding
        functional-idiom-advice-finding
        poo-direct-writeenv-finding
        poo-io-runtime-witness-finding
        poo-object-model-finding
        poo-method-shape-finding
        macro-runtime-source-witness-finding
        protocol-evidence-finding
        facade-export-conflict-findings)

(def +generic-owner-segments+
  '("utils" "util" "utility" "common" "helpers" "misc" "shared"))

(def +vague-definition-names+
  '("helper" "helpers" "process" "handle" "convert" "transform" "thing" "stuff" "do-it" "run-it"))

(def +poo-declarative-heads+
  '("defclass" ".defclass" ".defgeneric" "defmethod" ".defmethod"))

(def +poo-capability-dependencies+
  '("gerbil-poo" "clan/poo"))

(def +manual-object-model-callees+
  '("hash" "make-hash-table" "list->hash-table"))

(def +functional-idiom-roles+
  '("sequence-map"
    "sequence-filter"
    "sequence-filter-map"
    "sequence-append-map"
    "sequence-predicate"
    "sequence-search"
    "sequence-fold"
    "loop-fold"
    "partial-application"
    "function-curry"
    "function-composition"
    "list-builder"))

(def +functional-sequence-idioms+
  '("map" "filter" "filter-map" "append-map" "fold/foldl/foldr" "for/fold"))

(def +functional-predicate-idioms+
  '("andmap/ormap" "every/any" "find/list-index"))

(def +functional-composition-idioms+
  '("cut/cute" "curry/rcurry" "compose/compose1"))

(def +functional-preservation-control-roles+
  '("protected-control"
    "protected-handler"
    "continuation-control"
    "resource-scope"
    "builder-control"))

(def +macro-runtime-source-witness-explanation-min-length+ 32)
(def +macro-runtime-source-witness-min-length+ 8)

(def (run-agent-policy index)
  (append
   (facade-intent-findings index)
   (generic-owner-findings index)
   (vague-definition-findings index)
   (top-level-executable-findings index)
   (functional-idiom-advice-findings index)
   (poo-direct-writeenv-findings index)
   (poo-io-runtime-witness-findings index)
   (poo-object-model-findings index)
   (poo-method-shape-findings index)
   (macro-runtime-source-witness-findings index)
   (protocol-evidence-findings index)
   (facade-export-conflict-findings index)))

(def (facade-intent-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (not (facade-has-intent-doc? index file))
          (facade-intent-finding file)))
   (project-index-files index)))

(def (generic-owner-findings index)
  (filter-map
   (lambda (file)
     (let (segment (generic-owner-segment (source-file-path file)))
       (and segment (generic-owner-finding file segment))))
   (project-index-files index)))

(def (facade-has-intent-doc? index file)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap intent-comment?
            (take* (read-file-lines
                    (path-expand (source-file-path file)
                                 (project-index-root index)))
                   8)))))

(def (intent-comment? line)
  (let (text (string-trim line))
    (and (string-prefix? ";;;" text)
         (not (string-contains text "-*-")))))

(def (facade-intent-finding file)
  (make-type-finding
   (policy-rule-id +agent-intent-rule+)
   (policy-rule-severity +agent-intent-rule+)
   (source-file-path file)
   (string-append "facade " (source-file-path file)
                  " lacks an agent-readable intent comment")
   (source-file-path file)
   #f))

(def (generic-owner-segment path)
  (find (lambda (segment) (path-has-owner-segment? path segment))
        +generic-owner-segments+))

(def (path-has-owner-segment? path segment)
  (or (equal? path (string-append "src/" segment ".ss"))
      (string-contains path (string-append "/" segment ".ss"))
      (string-contains path (string-append "/" segment "/"))))

(def (generic-owner-finding file segment)
  (make-type-finding
   (policy-rule-id +agent-generic-owner-rule+)
   (policy-rule-severity +agent-generic-owner-rule+)
   (source-file-path file)
   (string-append "generic owner segment " segment
                  " hides the Gerbil module responsibility")
   (source-file-path file)
   (hash (segment segment))))

(def (vague-definition-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (definition)
                   (and (vague-definition-name? (definition-name definition))
                        (vague-definition-finding file definition)))
                 (source-file-definitions file)))
              (project-index-files index))))

(def (vague-definition-name? name)
  (member name +vague-definition-names+))

(def (vague-definition-finding file definition)
  (make-type-finding
   (policy-rule-id +agent-vague-definition-rule+)
   (policy-rule-severity +agent-vague-definition-rule+)
   (source-file-path file)
   (string-append "definition " (definition-name definition)
                  " is too vague for agent-written Gerbil; name the domain or data flow")
   (definition-selector definition)
   (hash (definition (definition-name definition))
         (selector (definition-selector definition)))))

(def (top-level-executable-findings index)
  (apply append
         (map (lambda (file)
              (filter-map
               (lambda (call)
                   (and (top-level-executable-call? index file call)
                        (top-level-executable-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))

(def (top-level-executable-call? index file call)
  (and (not (call-fact-caller call))
       (index-source-runtime-file-path? index (call-fact-path call))
       (not (poo-declarative-call? file call))))

(def (poo-declarative-call? file call)
  (and (poo-source-file? file)
       (ormap (lambda (form)
                (and (member (top-form-head form) +poo-declarative-heads+)
                     (equal? (top-form-selector form)
                             (call-fact-selector call))))
              (source-file-forms file))))

(def (poo-source-file? file)
  (ormap (lambda (import)
           (string-contains import "clan/poo"))
         (source-file-imports file)))

(def (poo-capability-active? index)
  (or (ormap poo-source-file? (project-index-files index))
      (ormap (lambda (fact)
               (member (poo-form-fact-role fact)
                       '("class" "generic" "method")))
             (project-poo-forms index))
      (let (package (project-index-package index))
        (and package
             (ormap poo-capability-dependency?
                    (project-package-dependencies package))))))

(def (poo-capability-dependency? dependency)
  (ormap (lambda (needle)
           (string-contains dependency needle))
         +poo-capability-dependencies+))

(def (source-runtime-file-path? path)
  (and (string-prefix? "src/" path)
       (string-suffix? ".ss" path)))

(def (index-source-runtime-file-path? index path)
  (and (string-suffix? ".ss" path)
       (let* ((package (project-index-package index))
              (policy (and package
                           (project-package-source-scope-policy package)))
              (roots (configured-runtime-roots policy)))
         (ormap (lambda (root)
                  (source-path-under-root? path root))
                roots))))

(def (configured-runtime-roots policy)
  (cond
   ((and policy (pair? (source-scope-policy-runtime-roots policy)))
    (source-scope-policy-runtime-roots policy))
   ((and policy (pair? (source-scope-policy-roots policy)))
    (source-scope-policy-roots policy))
   (else ["src"])))

(def (source-path-under-root? path root)
  (or (equal? root ".")
      (equal? path root)
      (string-prefix? (string-append root "/") path)))

(def (top-level-executable-finding file call)
  (make-type-finding
   (policy-rule-id +agent-top-level-executable-rule+)
   (policy-rule-severity +agent-top-level-executable-rule+)
   (source-file-path file)
   (string-append "top-level executable call " (call-fact-callee call)
                  " should move behind a named definition or explicit entrypoint")
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))

(def (functional-idiom-advice-findings index)
  (filter-map (cut functional-idiom-advice-finding index <>)
              (project-index-files index)))

(def (functional-idiom-advice-finding index file)
  (and (source-file-path file)
       (index-source-runtime-file-path? index (source-file-path file))
       (not (file-has-functional-idiom? file))
       (let (fact (manual-loop-control-flow file))
         (and fact
              (make-type-finding
               (policy-rule-id +agent-functional-idiom-advice-rule+)
               (policy-rule-severity +agent-functional-idiom-advice-rule+)
               (source-file-path file)
               "manual named let detected; if this is pure accumulation, predicate search, or sequence transformation, prefer for/fold, map/filter/filter-map/append-map, fold, predicate helpers, cut/curry/compose, or with-list-builder; keep named let for IO, stateful control flow, C3-style fixpoint selection, or generator/continuation drivers"
               (control-flow-fact-selector fact)
               (hash (name (control-flow-fact-name fact))
                     (kind (control-flow-fact-kind fact))
                     (selector (control-flow-fact-selector fact))
                     (advice "prefer parser-owned functional idioms for pure transforms")
                     (sequenceIdioms +functional-sequence-idioms+)
                     (predicateIdioms +functional-predicate-idioms+)
                     (compositionIdioms +functional-composition-idioms+)
                     (builderIdioms '("with-list-builder"))
                     (detectedControlContexts
                      (functional-preservation-control-contexts file))
                     (keepNamedLetWhen "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
                     (learnedFrom ".data/gerbil-utils/list.ss uses map/filter/fold/cut and keeps named let for C3 selection; generator.ss models coroutine control inversion; bytestring.ss uses for/fold for pure counts and named let for port IO")))))))

(def (manual-loop-control-flow file)
  (find (lambda (fact)
          (equal? (control-flow-fact-role fact) "manual-loop"))
        (source-file-control-flow-forms file)))

(def (file-has-functional-idiom? file)
  (ormap (lambda (fact)
           (member (higher-order-fact-role fact) +functional-idiom-roles+))
         (source-file-higher-order-forms file)))

(def (functional-preservation-control-contexts file)
  (map control-flow-fact-role
       (filter (lambda (fact)
                 (member (control-flow-fact-role fact)
                         +functional-preservation-control-roles+))
               (source-file-control-flow-forms file))))

(def (poo-direct-writeenv-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (and (direct-writeenv-call? call)
                        (poo-direct-writeenv-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))

(def (direct-writeenv-call? call)
  (equal? (call-fact-callee call) "writeenv"))

(def (poo-direct-writeenv-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-direct-writeenv-rule+)
   (policy-rule-severity +agent-poo-direct-writeenv-rule+)
   (source-file-path file)
   "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first"
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))

(def (poo-io-runtime-witness-findings index)
  (filter-map
   (lambda (file)
     (and (index-source-runtime-file-path? index (source-file-path file))
          (poo-io-source-file? file)
          (poo-io-method-override-file? file)
          (poo-io-runtime-witness-finding file)))
   (project-index-files index)))

(def (poo-io-source-file? file)
  (ormap poo-io-import? (source-file-imports file)))

(def (poo-io-import? import)
  (or (equal? import ":clan/poo/io")
      (equal? import "clan/poo/io")
      (string-contains import "clan/poo/io")))

(def (poo-io-method-override-file? file)
  (or (ormap (lambda (form)
               (member (top-form-head form)
                       ["defmethod" ".defmethod"]))
             (source-file-forms file))
      (ormap (lambda (call)
               (member (call-fact-callee call)
                       ["defmethod" ".defmethod"]))
             (source-file-calls file))))

(def (poo-io-runtime-witness-finding file)
  (make-type-finding
   (policy-rule-id +agent-poo-io-runtime-witness-rule+)
   (policy-rule-severity +agent-poo-io-runtime-witness-rule+)
   (source-file-path file)
   "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified"
   (source-file-path file)
   (hash (next "search runtime-source writeenv printer hook")
         (requiredWitness "writeenv-roundtrip-witness"))))

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

(def (manual-object-model-call? index file call)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (null? (source-file-poo-forms file))
       (member (call-fact-callee call) +manual-object-model-callees+)
       (call-fact-caller call)
       (or (string-prefix? "make-" (call-fact-caller call))
           (string-prefix? "new-" (call-fact-caller call))
           (string-prefix? "build-" (call-fact-caller call)))))

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

(def (poo-generic-fact-exists? index generic)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "generic")
          (equal? (poo-form-fact-generic fact) generic)))
   (project-poo-forms index)))

(def (poo-class-fact-exists? index class-name)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "class")
          (equal? (poo-form-fact-name fact) class-name)))
   (project-poo-forms index)))

(def (poo-receiver-evidence-exists? index name)
  (or (poo-class-fact-exists? index name)
      (poo-protocol-fact-exists? index name)))

(def (project-poo-forms index)
  (apply append (map source-file-poo-forms (project-index-files index))))

(def (blank-string? value)
  (or (not value) (equal? value "")))

(def (poo-method-shape-finding file fact missing)
  (make-type-finding
   (policy-rule-id +agent-poo-method-shape-rule+)
   (policy-rule-severity +agent-poo-method-shape-rule+)
   (source-file-path file)
   (string-append "POO method " (poo-form-fact-name fact)
                  " is missing parser-owned "
                  (join-missing missing)
                  " facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")
   (poo-form-fact-selector fact)
   (hash (generic (or (poo-form-fact-generic fact) ""))
         (receiverType (or (poo-form-fact-receiver-type fact) ""))
         (missing missing)
         (next "search pattern poo class protocol"))))

(def (macro-runtime-source-witness-findings index)
  (if (macro-runtime-source-policy-allows? index)
    '()
    (filter-map
     (lambda (file)
       (and (index-source-runtime-file-path? index (source-file-path file))
            (pair? (source-file-macros file))
            (macro-runtime-source-witness-finding
             file
             (car (source-file-macros file)))))
     (project-index-files index))))

(def (macro-runtime-source-policy-allows? index)
  (let (policy (project-macro-governance-policy index))
    (and policy
         (macro-runtime-source-explanation-clear? policy)
         (macro-runtime-source-witness-clear? policy))))

(def (project-macro-governance-policy index)
  (and (project-index-package index)
       (project-package-macro-governance-policy (project-index-package index))))

(def (macro-runtime-source-explanation-clear? policy)
  (and (macro-governance-policy-explanation policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-explanation policy)))
             +macro-runtime-source-witness-explanation-min-length+)))

(def (macro-runtime-source-witness-clear? policy)
  (and (macro-governance-policy-witness policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-witness policy)))
             +macro-runtime-source-witness-min-length+)))

(def (macro-runtime-source-witness-finding file fact)
  (make-type-finding
   (policy-rule-id +agent-macro-runtime-source-witness-rule+)
   (policy-rule-severity +agent-macro-runtime-source-witness-rule+)
   (source-file-path file)
   (string-append "macro " (macro-fact-name fact)
                  " needs runtime-source or macro-expansion witness before agent edits; query search runtime-source macro sugar module-sugar and record gerbil.pkg macro-governance witness")
   (macro-fact-selector fact)
   (hash (macro (macro-fact-name fact))
         (transformer (macro-fact-transformer fact))
         (selector (macro-fact-selector fact))
         (next "search runtime-source macro sugar module-sugar")
         (requiredWitness "gerbil.pkg policy macro-governance witness"))))

(def (protocol-evidence-findings index)
  (apply append
         (map (lambda (file)
                (if (protocol-context-file? file)
                  (filter-map
                   (lambda (fact)
                     (and (equal? (poo-form-fact-role fact) "method")
                          (not (blank-string? (poo-form-fact-receiver-type fact)))
                          (not (poo-protocol-fact-exists?
                                index
                                (poo-form-fact-receiver-type fact)))
                          (not (poo-class-fact-exists?
                                index
                                (poo-form-fact-receiver-type fact)))
                          (protocol-evidence-finding file fact)))
                   (source-file-poo-forms file))
                  '()))
              (project-index-files index))))

(def (protocol-context-file? file)
  (or (ormap protocol-import? (source-file-imports file))
      (ormap (lambda (fact)
               (equal? (poo-form-fact-role fact) "protocol"))
             (source-file-poo-forms file))))

(def (protocol-import? import)
  (and import (string-contains import "protocol")))

(def (poo-protocol-fact-exists? index protocol-name)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "protocol")
          (equal? (poo-form-fact-name fact) protocol-name)))
   (project-poo-forms index)))

(def (protocol-evidence-finding file fact)
  (make-type-finding
   (policy-rule-id +agent-protocol-evidence-rule+)
   (policy-rule-severity +agent-protocol-evidence-rule+)
   (source-file-path file)
   (string-append "protocol method " (poo-form-fact-name fact)
                  " specializes " (poo-form-fact-receiver-type fact)
                  " without parser-owned defprotocol/defclass evidence; declare protocol evidence before implementing methods")
   (poo-form-fact-selector fact)
   (hash (method (poo-form-fact-name fact))
         (receiverType (poo-form-fact-receiver-type fact))
         (generic (or (poo-form-fact-generic fact) ""))
         (next "search pattern poo protocol"))))

(def (join-missing items)
  (let lp ((rest items) (out ""))
    (match rest
      ([] out)
      ([item] (string-append out item))
      ([item . more] (lp more (string-append out item ","))))))

(def (facade-export-conflict-findings index)
  (let lp ((rest (facade-export-bindings index)) (seen '()) (out '()))
    (match rest
      ([binding . more]
       (let* ((name (car binding))
              (file (cdr binding))
              (prior (assoc name seen)))
         (cond
          ((and prior
                (not (equal? (source-file-path file)
                             (source-file-path (cdr prior)))))
           (lp more seen
               (cons (export-conflict-finding name file (cdr prior)) out)))
          (else
           (lp more (cons binding seen) out)))))
      (else (reverse out)))))

(def (facade-export-bindings index)
  (apply append
         (map (lambda (file)
                (if (facade-source-file? index file)
                  (map (lambda (name) (cons name file))
                       (source-file-exports file))
                  '()))
              (project-index-files index))))

(def (export-conflict-finding name file prior)
  (make-type-finding
   (policy-rule-id +agent-export-conflict-rule+)
   (policy-rule-severity +agent-export-conflict-rule+)
   (source-file-path file)
   (string-append "facade export " name
                  " conflicts with another facade export")
   (source-file-path file)
   (hash (export name)
         (firstPath (source-file-path prior))
         (duplicatePath (source-file-path file)))))

(def (take* items count)
  (let lp ((rest items) (remaining count) (out '()))
    (cond
     ((or (null? rest) (fx<= remaining 0)) (reverse out))
     (else (lp (cdr rest) (fx1- remaining) (cons (car rest) out))))))

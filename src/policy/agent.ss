;;; -*- Gerbil -*-
;;; Agent-facing policy checks over facade intent comments.

(import :gerbil/gambit
        :parser/facade
        :policy/agent-comment
        :policy/agent-dependency-adapter
        :policy/agent-import
        :policy/agent-poo
        :policy/agent-style
        :policy/agent-support
        :policy/model
        :policy/modularity
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13 string-contains string-prefix? string-trim)
        (only-in :std/sugar cut filter filter-map find hash ormap while with-catch)
        :support/list
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
        typed-combinator-style-finding
        comment-quality-finding
        controlled-branch-shape-finding
        predicate-family-combinator-finding
        dependency-protocol-adapter-finding
        explicit-precise-import-finding
        facade-export-conflict-findings)
;; ConfigConstant
(def +generic-owner-segments+
  '("utils" "util" "utility" "common" "helpers" "misc" "shared"))
;; ConfigConstant
(def +vague-definition-names+
  '("helper" "helpers" "process" "handle" "convert" "transform" "thing" "stuff" "do-it" "run-it"))
;; String
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
;; Integer
(def +functional-sequence-idioms+
  '("map" "filter" "filter-map" "append-map" "fold/foldl/foldr" "for/fold"))
;; Integer
(def +functional-predicate-idioms+
  '("andmap/ormap" "every/any" "find/list-index"))
;; Integer
(def +functional-composition-idioms+
  '("cut/cute" "curry/rcurry" "compose/compose1"))
;; String
(def +functional-preservation-control-roles+
  '("protected-control"
    "protected-handler"
    "continuation-control"
    "resource-scope"
    "builder-control"))
;; String
(def +functional-preservation-reader-callees+
  '("read" "read-char" "read-line" "read-syntax"))
;; FFI forms declare native ABI surfaces at module load/compile time.
;; Treat their nested parser call facts as declarations, not executable effects.
(def +declarative-top-level-heads+
  '("declare" "c-declare" "c-define-type" "define-c-lambda"
    "begin-ffi" "begin-foreign" "c-define" "namespace"))
;; Integer
(def +macro-runtime-source-witness-explanation-min-length+ 32)
;; Integer
(def +macro-runtime-source-witness-min-length+ 8)
;; (List TypeFinding) <- ProjectIndex
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
   (typed-combinator-style-findings index)
   (comment-quality-findings index)
   (controlled-branch-shape-findings index)
   (predicate-family-combinator-findings index)
   (dependency-protocol-adapter-findings index)
   (explicit-precise-import-findings index)
   (facade-export-conflict-findings index)))
;;; Boundary:
;;; - facade-intent-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (facade-intent-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (not (facade-has-intent-doc? index file))
          (facade-intent-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - generic-owner-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (generic-owner-findings index)
  (filter-map
   (lambda (file)
     (let (segment (generic-owner-segment (source-file-path file)))
       (and segment (generic-owner-finding file segment))))
   (project-index-files index)))
;;; Boundary:
;;; - facade-has-intent-doc? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex SourceFile
(def (facade-has-intent-doc? index file)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap intent-comment?
            (take* (read-file-lines
                    (path-expand (source-file-path file)
                                 (project-index-root index)))
                   8)))))
;; Boolean <- SourceLine
(def (intent-comment? line)
  (let (text (string-trim line))
    (and (string-prefix? ";;;" text)
         (not (string-contains text "-*-")))))
;; TypeFinding <- SourceFile
(def (facade-intent-finding file)
  (make-type-finding
   (policy-rule-id +agent-intent-rule+)
   (policy-rule-severity +agent-intent-rule+)
   (source-file-path file)
   (string-append "facade " (source-file-path file)
                  " lacks an agent-readable intent comment")
   (source-file-path file)
   #f))
;;; Boundary:
;;; - generic-owner-segment composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; GenericOwnerSegment <- String
(def (generic-owner-segment path)
  (find (lambda (segment) (path-has-owner-segment? path segment))
        +generic-owner-segments+))
;; Boolean <- String Segment
(def (path-has-owner-segment? path segment)
  (or (equal? path (string-append "src/" segment ".ss"))
      (string-contains path (string-append "/" segment ".ss"))
      (string-contains path (string-append "/" segment "/"))))
;; TypeFinding <- SourceFile Segment
(def (generic-owner-finding file segment)
  (make-type-finding
   (policy-rule-id +agent-generic-owner-rule+)
   (policy-rule-severity +agent-generic-owner-rule+)
   (source-file-path file)
   (string-append "generic owner segment " segment
                  " hides the Gerbil module responsibility")
   (source-file-path file)
   (hash (segment segment))))
;;; Boundary:
;;; - vague-definition-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (vague-definition-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (definition)
                   (and (vague-definition-name? (definition-name definition))
                        (vague-definition-finding file definition)))
                 (source-file-definitions file)))
              (project-index-files index))))
;; Boolean <- String
(def (vague-definition-name? name)
  (member name +vague-definition-names+))
;; TypeFinding <- SourceFile Definition
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
;;; Boundary:
;;; - top-level-executable-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (top-level-executable-findings index)
  (apply append
         (map (lambda (file)
              (filter-map
               (lambda (call)
                   (and (top-level-executable-call? index file call)
                        (top-level-executable-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))
;; Boolean <- ProjectIndex SourceFile CallFact
(def (top-level-executable-call? index file call)
  (and (not (call-fact-caller call))
       (index-source-runtime-file-path? index (call-fact-path call))
       (not (explicit-runtime-entrypoint-path? (call-fact-path call)))
       (not (declarative-top-level-call? file call))))

;; Boolean <- SourceFile CallFact
(def (declarative-top-level-call? file call)
  (or (poo-declarative-call? file call)
      (ffi-declarative-call? file call)))

;;; Boundary: FFI top forms run at expansion time, so nested call facts are declarations.
;; Boolean <- SourceFile CallFact
(def (ffi-declarative-call? file call)
  (ormap (lambda (form)
           (and (declarative-top-form? form)
                (call-within-top-form-range? call form)))
         (source-file-forms file)))
;; Boolean <- TopForm
(def (declarative-top-form? form)
  (member (top-form-head form) +declarative-top-level-heads+))
;; Boolean <- CallFact TopForm
(def (call-within-top-form-range? call form)
  (and (<= (top-form-start form) (call-fact-start call))
       (>= (top-form-end form) (call-fact-end call))))
;;; Boundary:
;;; - poo-declarative-call? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- SourceFile CallFact
(def (poo-declarative-call? file call)
  (and (poo-source-file? file)
       (ormap (lambda (form)
                (and (member (top-form-head form) +poo-declarative-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))
;; TypeFinding <- SourceFile CallFact
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

;;; Boundary:
;;; - functional-idiom-advice-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (functional-idiom-advice-findings index)
  (filter-map (cut functional-idiom-advice-finding index <>)
              (project-index-files index)))
;;; Boundary:
;;; - functional-idiom-advice-finding coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; TypeFinding <- ProjectIndex SourceFile
(def (functional-idiom-advice-finding index file)
  (and (source-file-path file)
       (index-source-runtime-file-path? index (source-file-path file))
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
                     (caller (or (control-flow-fact-caller fact) ""))
                     (advice "prefer parser-owned functional idioms for pure transforms")
                     (sequenceIdioms +functional-sequence-idioms+)
                     (predicateIdioms +functional-predicate-idioms+)
                     (compositionIdioms +functional-composition-idioms+)
                     (builderIdioms '("with-list-builder"))
                     (styleGuide "typed-combinator-style")
                     (styleCommand "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
                     (detectedControlContexts
                      (functional-preservation-control-contexts file))
                     (keepNamedLetWhen "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
                     (learnedFrom ".data/gerbil-utils/list.ss uses small typed-commented helpers with map/filter/fold/cut and keeps named let for C3 selection; generator.ss models coroutine control inversion; bytestring.ss uses for/fold for pure counts and named let for port IO")))))))
;;; Boundary:
;;; Manual-loop advice is caller scoped.
;;; A map/fold in one helper must not hide a separate low-quality loop.
;; (List ControlFlowFact) <- SourceFile
(def (manual-loop-control-flow file)
  (find (lambda (fact)
          (and (equal? (control-flow-fact-role fact) "manual-loop")
               (not (caller-has-functional-idiom? file
                                                  (control-flow-fact-caller fact)))
               (not (caller-has-reader-boundary? file
                                                 (control-flow-fact-caller fact)))))
        (source-file-control-flow-forms file)))
;;; Boundary:
;;; - caller-has-functional-idiom? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- SourceFile Caller
(def (caller-has-functional-idiom? file caller)
  (ormap (lambda (fact)
           (and (equal? (or (higher-order-fact-caller fact) "") (or caller ""))
                (member (higher-order-fact-role fact) +functional-idiom-roles+)))
         (source-file-higher-order-forms file)))
;;; Boundary:
;;; Reader callees are native parser witnesses for port state and EOF handling.
;;; The ormap/lambda pair keeps preservation caller-scoped, so one reader loop
;;; does not suppress unrelated manual-loop repair in the same file.
;; Boolean <- SourceFile Caller
(def (caller-has-reader-boundary? file caller)
  (ormap (lambda (fact)
           (and (equal? (or (call-fact-caller fact) "") (or caller ""))
                (reader-boundary-callee? (call-fact-callee fact))))
         (source-file-calls file)))

;; Boolean <- Callee
(def (reader-boundary-callee? callee)
  (and callee
       (or (member callee +functional-preservation-reader-callees+)
           (string-prefix? "read-" callee))))
;;; Boundary:
;;; - functional-preservation-control-contexts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; FunctionalPreservationControlContexts <- SourceFile
(def (functional-preservation-control-contexts file)
  (map control-flow-fact-role
       (filter (lambda (fact)
                 (member (control-flow-fact-role fact)
                         +functional-preservation-control-roles+))
               (source-file-control-flow-forms file))))
;;; Boundary:
;;; - macro-runtime-source-witness-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
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
;; Boolean <- ProjectIndex
(def (macro-runtime-source-policy-allows? index)
  (let (policy (project-macro-governance-policy index))
    (and policy
         (macro-runtime-source-explanation-clear? policy)
         (macro-runtime-source-witness-clear? policy))))
;; ProjectMacroGovernancePolicy <- ProjectIndex
(def (project-macro-governance-policy index)
  (and (project-index-package index)
       (project-package-macro-governance-policy (project-index-package index))))
;; Boolean <- Policy
(def (macro-runtime-source-explanation-clear? policy)
  (and (macro-governance-policy-explanation policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-explanation policy)))
             +macro-runtime-source-witness-explanation-min-length+)))
;; Boolean <- Policy
(def (macro-runtime-source-witness-clear? policy)
  (and (macro-governance-policy-witness policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-witness policy)))
             +macro-runtime-source-witness-min-length+)))
;; TypeFinding <- SourceFile Fact
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
;;; Boundary:
;;; - protocol-evidence-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- ProjectIndex
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
;;; Boundary:
;;; - protocol-context-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- SourceFile
(def (protocol-context-file? file)
  (or (ormap protocol-import? (source-file-imports file))
      (ormap (lambda (fact)
               (equal? (poo-form-fact-role fact) "protocol"))
             (source-file-poo-forms file))))
;; Boolean <- String
(def (protocol-import? import)
  (and import (string-contains import "protocol")))
;; String <- SourceFile Fact
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
;;; Invariant:
;;; - facade-export-conflict-findings owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List TypeFinding) <- ProjectIndex
(def (facade-export-conflict-findings index)
  (let ((rest (facade-export-bindings index))
        (seen '())
        (out '()))
    (while (pair? rest)
      (let* ((binding (car rest))
             (name (car binding))
             (file (cdr binding))
             (prior (assoc name seen)))
        (if (and prior
                 (not (equal? (source-file-path file)
                              (source-file-path (cdr prior)))))
          (set! out (cons (export-conflict-finding name file (cdr prior)) out))
          (set! seen (cons binding seen)))
        (set! rest (cdr rest))))
    (reverse out)))
;;; Boundary:
;;; - facade-export-bindings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List BindingFact) <- ProjectIndex
(def (facade-export-bindings index)
  (apply append
         (map (lambda (file)
                (if (facade-source-file? index file)
                  (map (lambda (name) (cons name file))
                       (source-file-exports file))
                  '()))
              (project-index-files index))))
;; TypeFinding <- String SourceFile ControlFlowGroup
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

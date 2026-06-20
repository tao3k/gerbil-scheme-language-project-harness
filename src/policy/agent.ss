;;; -*- Gerbil -*-
;;; Agent-facing policy checks over facade intent comments.

(import :gerbil/gambit
        :parser/facade
        :policy/agent-alist-access
        :policy/agent-anonymous-pair
        :policy/agent-build
        :policy/agent-build-support
        :policy/agent-comment
        :policy/agent-dependency-adapter
        :policy/agent-import
        :policy/agent-poo
        :policy/agent-source-scope
        :policy/agent-style
        :policy/agent-support
        :policy/gerbil-utils-source
        :policy/model
        :policy/modularity
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13
                 string-contains
                 string-prefix?
                 string-suffix?
                 string-trim)
        (only-in :std/sugar cut filter filter-map find hash ormap while with-catch)
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
        package-build-responsibility-finding
        build-runtime-quality-finding
        policy-source-scope-finding
        alist-access-finding
        anonymous-pair-access-finding
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
  '("cut/cute" "curry/rcurry" "compose/compose1" "!>/!!>"))
;; Integer
(def +functional-native-lambda-idioms+
  '("fun" "lambda-match/λ-match" "λ" "case-lambda"))
;; Integer
(def +functional-typeclass-idioms+
  '("gerbil-poo/fun.ss Category." "Functor." "ParametricFunctor."
    "Wrapper./Wrap." "methods.table protocol slots"))
;; String
(def +functional-preservation-control-roles+
  '("protected-control"
    "protected-handler"
    "cleanup-boundary"
    "continuation-control"
    "resource-scope"
    "parameter-state"
    "builder-control"
    "actor-control"
    "coroutine-control"))
;; String
(def +redundant-manual-loop-required-signals+
  '("named-let"
    "manual-loop-role"
    "multi-binding-loop-state"
    "no-functional-idiom-witness"
    "no-reader-boundary"
    "no-control-preservation-context"))
;; String
(def +functional-preservation-reader-callees+
  '("read" "read-char" "read-line" "read-syntax"))
;; Integer
(def +macro-runtime-source-witness-explanation-min-length+ 32)
;; Integer
(def +macro-runtime-source-witness-min-length+ 8)
;;; Agent policy aggregation boundary:
;;; - Specific semantic/style rules run before self-audit rules.
;;; - Self-audit findings then catch policy implementation shortcuts such as
;;;   path-scope hardcoding and repeated inline alist lookup.
;;; - Export conflict checks remain last because they compare accumulated facade bindings.
;; : (-> ProjectIndex (List TypeFinding) )
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
   (package-build-responsibility-findings index)
   (package-build-canonical-shape-findings index)
   (build-runtime-quality-findings index)
   (policy-source-scope-findings index)
   (alist-access-findings index)
   (anonymous-pair-access-findings index)
   (facade-export-conflict-findings index)))
;;; Boundary:
;;; - facade-intent-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
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
;; : (-> ProjectIndex (List TypeFinding) )
(def (generic-owner-findings index)
  (filter-map
   (lambda (file)
     (let (segment (generic-owner-segment (source-file-path file)))
       (and segment (generic-owner-finding file segment))))
   (project-index-files index)))
;;; Boundary:
;;; - facade-has-intent-doc? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex SourceFile Boolean )
(def (facade-has-intent-doc? index file)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (lines (read-file-lines
                  (path-expand (source-file-path file)
                               (project-index-root index))))
       (ormap intent-comment?
              (take lines (min 8 (length lines))))))))
;; : (-> SourceLine Boolean )
(def (intent-comment? line)
  (let (text (string-trim line))
    (and (string-prefix? ";;;" text)
         (not (string-contains text "-*-")))))
;; : (-> SourceFile TypeFinding )
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
;; : (-> String GenericOwnerSegment )
(def (generic-owner-segment path)
  (find (lambda (segment) (path-has-owner-segment? path segment))
        +generic-owner-segments+))
;; : (-> String Segment Boolean )
(def (path-has-owner-segment? path segment)
  (or (equal? path (string-append "src/" segment ".ss"))
      (string-contains path (string-append "/" segment ".ss"))
      (string-contains path (string-append "/" segment "/"))))
;; : (-> SourceFile Segment TypeFinding )
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
;; : (-> ProjectIndex (List TypeFinding) )
(def (vague-definition-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (definition)
                   (and (vague-definition-name? (definition-name definition))
                        (vague-definition-finding file definition)))
                 (source-file-definitions file)))
              (project-index-files index))))
;; : (-> String Boolean )
(def (vague-definition-name? name)
  (member name +vague-definition-names+))
;; : (-> SourceFile Definition TypeFinding )
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
;; : (-> ProjectIndex (List TypeFinding) )
(def (top-level-executable-findings index)
  (apply append
         (map (lambda (file)
              (filter-map
               (lambda (call)
                   (and (top-level-executable-call? index file call)
                        (top-level-executable-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))
;; : (-> ProjectIndex SourceFile CallFact Boolean )
(def (top-level-executable-call? index file call)
  (and (top-level-runtime-call? index call)
       (not (top-level-entrypoint-exempt-call? file call))))

;; : (-> ProjectIndex CallFact Boolean )
(def (top-level-runtime-call? index call)
  (and (not (call-fact-caller call))
       (index-source-runtime-file-path? index (call-fact-path call))))

;; : (-> SourceFile CallFact Boolean )
(def (top-level-entrypoint-exempt-call? file call)
  (or (explicit-runtime-entrypoint-path? (call-fact-path call))
      (explicit-main-entrypoint-call? file call)
      (explicit-test-entrypoint-call? file call)
      (declarative-top-level-call? file call)))

;; (List TopFormHead)
(def +explicit-main-entrypoint-heads+
  '("main" "apply" "exit"))

;; (List TopFormHead)
(def +explicit-test-entrypoint-heads+
  '("run-tests!"))

;;; Boundary:
;;; - Explicit entrypoints are language-level contracts, not path hacks.
;;; - Exported main plus a top-level main/apply/exit form is treated as the
;;;   script boundary.
;;; - Arbitrary top-level calls still fail R005.
;; : (-> SourceFile CallFact Boolean )
(def (explicit-main-entrypoint-call? file call)
  (and (member "main" (source-file-exports file))
       (ormap (lambda (form)
                (and (member (top-form-head form)
                             +explicit-main-entrypoint-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))

;;; Boundary:
;;; - Test harness entrypoints are explicit execution boundaries.
;;; - Keep this shape-based: only test owners with a run-tests! top form are
;;;   exempt, not every arbitrary call in t/.
;; : (-> SourceFile CallFact Boolean )
(def (explicit-test-entrypoint-call? file call)
  (and (test-owner-path? (source-file-path file))
       (ormap (lambda (form)
                (and (member (top-form-head form)
                             +explicit-test-entrypoint-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))

;; : (-> Path Boolean )
(def (test-owner-path? path)
  (or (string-prefix? "t/" path)
      (string-contains path "/t/")
      (string-suffix? "-test.ss" path)))

;; : (-> SourceFile CallFact Boolean )
(def (declarative-top-level-call? file call)
  (or (poo-declarative-call? file call)
      (ffi-declarative-call? file call)))

;;; Boundary: FFI top forms run at expansion time, so nested call facts are declarations.
;; : (-> SourceFile CallFact Boolean )
(def (ffi-declarative-call? file call)
  (ormap (lambda (form)
           (and (declarative-top-form? form)
                (call-within-top-form-range? call form)))
         (source-file-forms file)))
;; : (-> CallFact TopForm Boolean )
(def (call-within-top-form-range? call form)
  (and (<= (top-form-start form) (call-fact-start call))
       (>= (top-form-end form) (call-fact-end call))))
;;; Boundary:
;;; - poo-declarative-call? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile CallFact Boolean )
(def (poo-declarative-call? file call)
  (and (poo-source-file? file)
       (ormap (lambda (form)
                (and (member (top-form-head form) +poo-declarative-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))
;; : (-> SourceFile CallFact TypeFinding )
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
;; : (-> ProjectIndex (List TypeFinding) )
(def (functional-idiom-advice-findings index)
  (filter-map (cut functional-idiom-advice-finding index <>)
              (project-index-files index)))
;;; Boundary:
;;; - functional-idiom-advice-finding coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> ProjectIndex SourceFile TypeFinding )
(def (functional-idiom-advice-finding index file)
  (and (source-file-path file)
       (index-source-runtime-file-path? index (source-file-path file))
       (let (fact (manual-loop-control-flow file))
         (and fact
              (make-type-finding
               (policy-rule-id +agent-functional-idiom-advice-rule+)
               (policy-rule-severity +agent-functional-idiom-advice-rule+)
               (source-file-path file)
               "named-let loop looks like a redundant pure transform; prefer for/fold, map/filter/filter-map/append-map, fold, predicate helpers, cut/curry/compose, or with-list-builder only when parser facts show no IO, stateful control flow, C3-style fixpoint selection, or generator/continuation driver"
               (control-flow-fact-selector fact)
               (hash (name (control-flow-fact-name fact))
                     (kind (control-flow-fact-kind fact))
                     (selector (control-flow-fact-selector fact))
                     (caller (or (control-flow-fact-caller fact) ""))
                     (namedLetPolicy "warn-on-redundant-pure-transform-only")
                     (detectionSignals
                      (manual-loop-detection-signals file fact))
                     (advice "prefer parser-owned functional idioms for pure transforms")
                     (sequenceIdioms +functional-sequence-idioms+)
                     (predicateIdioms +functional-predicate-idioms+)
                     (compositionIdioms +functional-composition-idioms+)
                     (nativeLambdaIdioms +functional-native-lambda-idioms+)
                     (typeclassIdioms +functional-typeclass-idioms+)
                     (builderIdioms '("with-list-builder"))
                     (styleGuide "typed-combinator-style")
                     (styleCommand "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
                     (detectedControlContexts
                      (functional-preservation-control-contexts file))
                     (callerControlContexts
                      (caller-functional-preservation-control-contexts
                       file
                       (control-flow-fact-caller fact)))
                     (keepNamedLetWhen "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
                     (preserveNamedLetWhen
                      '("local recursion without accumulator boilerplate"
                        "reader or port EOF loops"
                        "stateful control flow"
                        "C3-style fixpoint selection"
                        "generator, coroutine, actor, or continuation driver"))
                     (learnedFrom ".data/gerbil-utils/base.ss exposes λ/lambda-match/compose/!>/curry/rcurry/fun for compact higher-order helpers; .data/gerbil-poo/fun.ss models Category./Functor./ParametricFunctor. algebra; table.ss methods.table shows protocol slots plus derived table/list/sexp/json/marshal capability; named let remains valid for C3 selection, reader IO, and coroutine control")))))))
;;; Boundary:
;;; Manual-loop advice is caller scoped and multi-signal.
;;; Named let remains valid Gerbil.
;;; Only redundant pure-transform shapes warn.
;; : (-> SourceFile (List ControlFlowFact) )
(def (manual-loop-control-flow file)
  (find (cut redundant-manual-loop-control-flow? file <>)
        (source-file-control-flow-forms file)))
;;; Signal gate: R009 should only fire when every native-parser witness points
;;; at redundant pure-transform boilerplate, not at named-let usage itself.
;; : (-> SourceFile ControlFlowFact Boolean )
(def (redundant-manual-loop-control-flow? file fact)
  (let (signals (manual-loop-detection-signals file fact))
    (not (find (lambda (signal)
                 (not (member signal signals)))
               +redundant-manual-loop-required-signals+))))
;;; Evidence packet: keep positive and negative witnesses visible so repair
;;; agents can explain why this loop is redundant before rewriting it.
;; : (-> SourceFile ControlFlowFact (List String) )
(def (manual-loop-detection-signals file fact)
  (let (caller (control-flow-fact-caller fact))
    (filter identity
            [(and (equal? (control-flow-fact-kind fact) "named-let")
                  "named-let")
             (and (equal? (control-flow-fact-role fact) "manual-loop")
                  "manual-loop-role")
             (and (manual-loop-multi-binding-state? fact)
                  "multi-binding-loop-state")
             (and (not (caller-has-functional-idiom? file caller))
                  "no-functional-idiom-witness")
             (and (not (caller-has-reader-boundary? file caller))
                  "no-reader-boundary")
             (and (not (caller-has-preservation-control-context? file caller))
                  "no-control-preservation-context")])))
;;; Shape signal: two or more loop bindings usually means threaded rest/acc
;;; state, so it is only advisory when the other absence witnesses also agree.
;; : (-> ControlFlowFact Boolean )
(def (manual-loop-multi-binding-state? fact)
  (>= (control-flow-fact-binding-count fact) 2))
;;; Boundary:
;;; - caller-has-functional-idiom? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Caller Boolean )
(def (caller-has-functional-idiom? file caller)
  (ormap (lambda (fact)
           (and (equal? (or (higher-order-fact-caller fact) "") (or caller ""))
                (member (higher-order-fact-role fact) +functional-idiom-roles+)))
         (source-file-higher-order-forms file)))
;;; Boundary:
;;; Reader callees are native parser witnesses for port state and EOF handling.
;;; The ormap/lambda pair keeps preservation caller-scoped, so one reader loop
;;; does not suppress unrelated manual-loop repair in the same file.
;; : (-> SourceFile Caller Boolean )
(def (caller-has-reader-boundary? file caller)
  (ormap (lambda (fact)
           (and (equal? (or (call-fact-caller fact) "") (or caller ""))
                (reader-boundary-callee? (call-fact-callee fact))))
         (source-file-calls file)))

;; : (-> Callee Boolean )
(def (reader-boundary-callee? callee)
  (and callee
       (or (member callee +functional-preservation-reader-callees+)
           (string-prefix? "read-" callee))))
;;; Suppression gate: preservation evidence must live in the same caller as the
;;; named-let; an unrelated continuation in the file must not hide a bad loop.
;; : (-> SourceFile Caller Boolean )
(def (caller-has-preservation-control-context? file caller)
  (pair? (caller-functional-preservation-control-contexts file caller)))
;;; Boundary:
;;; Preservation contexts are caller scoped for suppression.
;;; File-level contexts still surface in finding details as repair evidence.
;; : (-> SourceFile Caller FunctionalPreservationControlContexts )
(def (caller-functional-preservation-control-contexts file caller)
  (map control-flow-fact-role
       (filter (lambda (fact)
                 (and (equal? (or (control-flow-fact-caller fact) "")
                              (or caller ""))
                      (member (control-flow-fact-role fact)
                              +functional-preservation-control-roles+)))
               (source-file-control-flow-forms file))))
;;; Boundary:
;;; - functional-preservation-control-contexts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile FunctionalPreservationControlContexts )
(def (functional-preservation-control-contexts file)
  (map control-flow-fact-role
       (filter (lambda (fact)
                 (member (control-flow-fact-role fact)
                         +functional-preservation-control-roles+))
               (source-file-control-flow-forms file))))
;;; Boundary:
;;; - macro-runtime-source-witness-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
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
;; : (-> ProjectIndex Boolean )
(def (macro-runtime-source-policy-allows? index)
  (let (policy (project-macro-governance-policy index))
    (and policy
         (macro-runtime-source-explanation-clear? policy)
         (macro-runtime-source-witness-clear? policy))))
;; : (-> ProjectIndex ProjectMacroGovernancePolicy )
(def (project-macro-governance-policy index)
  (and (project-index-package index)
       (project-package-macro-governance-policy (project-index-package index))))
;; : (-> Policy Boolean )
(def (macro-runtime-source-explanation-clear? policy)
  (and (macro-governance-policy-explanation policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-explanation policy)))
             +macro-runtime-source-witness-explanation-min-length+)))
;; : (-> Policy Boolean )
(def (macro-runtime-source-witness-clear? policy)
  (and (macro-governance-policy-witness policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-witness policy)))
             +macro-runtime-source-witness-min-length+)))
;;; Finding boundary:
;;; - The macro fact supplies selector and syntax evidence.
;;; - Details tell agents to fetch runtime-source witnesses before editing macros.
;; : (-> SourceFile MacroFact TypeFinding )
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
         (phase (macro-fact-phase fact))
         (patternCount (macro-fact-pattern-count fact))
         (hygienic (macro-fact-hygienic fact))
         (qualityFacets (macro-fact-quality-facets fact))
         (selector (macro-fact-selector fact))
         (macroFactSource "parser-owned macroFacts from native Gerbil syntax extraction")
         (policyBoundary "macros are allowed when they stay controlled, source-backed, and explainable")
         (runtimeSourceRequirement
          (hash (authority "runtime-version-source")
                (selectorScheme "gerbil-runtime-source")
                (selectorFormat "gerbil-runtime-source://<source-path>#<symbol>")
                (output "code-with-comments")
                (indexOwner "asp-structural-index")))
         (gerbilUtilsSource
          (gerbil-utils-source-details 'macro-helper))
         (allowedMacroShape
          ["thin syntax bridge"
           "syntax-case transformer with local parsing helpers"
           "defrule/defrules wrapper over visible runtime behavior"
           "for-syntax helper with precise imports"])
         (agentEscapeConstraint
          "do not weaken macro-governance from a source macro edit; update gerbil.pkg only with a clear explanation and witness")
         (next "search runtime-source macro sugar module-sugar")
         (requiredWitness "gerbil.pkg policy macro-governance witness"))))
;;; Boundary:
;;; - protocol-evidence-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex String )
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
;; : (-> SourceFile Boolean )
(def (protocol-context-file? file)
  (or (ormap protocol-import? (source-file-imports file))
      (ormap (lambda (fact)
               (equal? (poo-form-fact-role fact) "protocol"))
             (source-file-poo-forms file))))
;; : (-> String Boolean )
(def (protocol-import? import)
  (and import (string-contains import "protocol")))
;; : (-> SourceFile Fact String )
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
;; : (-> ProjectIndex (List TypeFinding) )
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
;; : (-> ProjectIndex (List BindingFact) )
(def (facade-export-bindings index)
  (apply append
         (map (lambda (file)
                (if (facade-source-file? index file)
                  (map (lambda (name) (cons name file))
                       (source-file-exports file))
                  '()))
              (project-index-files index))))
;; : (-> String SourceFile ControlFlowGroup TypeFinding )
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

;;; -*- Gerbil -*-
;;; Agent-facing build/runtime support quality policy.

(import :parser/facade
        :policy/model
        (only-in :std/srfi/13 string-contains string-prefix? string-suffix?)
        (only-in :std/sugar cut filter filter-map hash ormap)
        :types/findings)

(export build-runtime-quality-findings
        build-runtime-quality-finding)

;; Integer
(def +build-runtime-min-evidence-groups+ 2)
;; Integer
(def +build-runtime-min-shell-helper-definitions+ 2)
;; Integer
(def +build-runtime-min-shell-control-markers+ 2)

;; (List String)
(def +shell-helper-definition-markers+
  '("shell-" "-shell-" "sh-"))

;; (List String)
(def +shell-control-literal-markers+
  '("#!/bin/sh"
    "#!/usr/bin/env sh"
    "set -eu"
    "if ["
    "case "
    "esac"
    "fi\n"
    "$@"
    "${"
    "&&"
    "||"
    "trap "
    "exec "
    "|"
    "xargs"))

;; (List String)
(def +shell-pipeline-literal-markers+
  '("|" "xargs" "find src" "sort |" " -P "))

;; (List String)
(def +shell-dispatch-callees+
  '("invoke" "run-process" "open-process"))

;;; Boundary:
;;; - Quality findings are composite gates over parser-owned definitions and
;;;   call arguments.
;;; - A single string marker is advisory evidence only.
;; (List TypeFinding) <- ProjectIndex
(def (build-runtime-quality-findings index)
  (filter-map build-runtime-quality-finding
              (project-index-files index)))

;;; Finding contract:
;;; - build-support files are allowed to install Gerbil launchers.
;;; - shell templates and sh -c pipelines require at least two evidence groups.
;; MaybeTypeFinding <- SourceFile
(def (build-runtime-quality-finding file)
  (let (groups (build-runtime-quality-evidence-groups file))
    (and (build-runtime-composite-evidence? groups)
         (make-type-finding
          (policy-rule-id +agent-build-runtime-quality-rule+)
          (policy-rule-severity +agent-build-runtime-quality-rule+)
          (source-file-path file)
          "build/runtime support code is drifting back to shell-template or sh -c pipeline orchestration; use Gerbil runtime sources, std/misc/process, list command arguments, and small launcher/config writers"
          (build-runtime-evidence-selector file groups)
          (runtime-quality-details groups)))))

;;; Intentional raw data record:
;;; - Details stay JSON-shaped for command output because TypeFinding receipts
;;;   cross the provider JSON boundary as key/value diagnostic evidence.
;;; - This is not runtime object construction or a dependency protocol adapter.
;; PolicyDetails <- (List EvidenceGroup)
(def (runtime-quality-details groups)
  (hash (kind "build-runtime-quality")
        (evidenceGroups (map evidence-group-name groups))
        (evidenceCounts (map evidence-group-count groups))
        (evidenceSelectors (map evidence-group-selector groups))
        (requiredEvidence "at least two independent parser-owned groups")
        (allowedShape "Gerbil runtime wrapper source plus list command arguments")
        (disallowedShape "generated shell templates or sh -c pipelines")
        (next "move behavior into build-support/*-runtime.ss or normal Gerbil helpers; keep launchers as data/config writers")))

;;; Dispatch boundary keeps build-support and package build checks separate:
;;; launcher files are allowed to write executables, while build.ss is only
;;; checked for shell pipeline orchestration.
;; (List EvidenceGroup) <- SourceFile
(def (build-runtime-quality-evidence-groups file)
  (cond
   ((build-support-source-file? file)
    (build-support-shell-template-evidence-groups file))
   ((package-build-file? file)
    (package-build-shell-pipeline-evidence-groups file))
   (else '())))

;;; Composite evidence prevents noisy single-token findings from strings that
;;; are legitimate launcher snippets; at least two parser-owned groups must
;;; agree before this policy emits a warning.
;; Boolean <- (List EvidenceGroup)
(def (build-runtime-composite-evidence? groups)
  (>= (length groups) +build-runtime-min-evidence-groups+))

;;; Launcher quality is checked through independent signals: helper naming,
;;; shell-control literals, and writer calls. This keeps generated scripts
;;; possible while catching shell-template drift.
;; (List EvidenceGroup) <- SourceFile
(def (build-support-shell-template-evidence-groups file)
  (filter-map (cut <> file)
              [shell-helper-definition-evidence
               shell-control-literal-evidence
               shell-writer-call-evidence]))

;;; Boundary:
;;; - build.ss orchestration should stay in Gerbil argv lists.
;;; - filter-map keeps dispatch and payload evidence independent.
;;; - The composite gate decides whether those groups become a warning.
;;; Data flow:
;;; - Each extractor consumes the same SourceFile and returns maybe one group,
;;;   so filter-map is the exact maybe-projection shape.
;;; Invariant:
;;; - The cut thunk preserves extractor arity and selector order as new groups
;;;   are added.
;; (List EvidenceGroup) <- SourceFile
(def (package-build-shell-pipeline-evidence-groups file)
  (filter-map (cut <> file)
              [shell-dispatch-call-evidence
               shell-pipeline-literal-evidence]))

;;; Data flow:
;;; The source file provides parser-owned DefinitionFact values.
;;; filter applies shell-helper-definition? to each DefinitionFact.
;;; The filtered list keeps parser order for selector choice.
;;; Arity evidence:
;;; shell-helper-definition? accepts one DefinitionFact.
;;; filter keeps the list shape and does not synthesize selectors.
;;; Invariant:
;;; Helper names are soft evidence only.
;;; The composite gate owns the decision to emit a finding.
;;; Hidden invariant:
;;; A manual loop could select a later helper.
;;; That would make finding selectors unstable across parser order changes.
;; MaybeEvidenceGroup <- SourceFile
(def (shell-helper-definition-evidence file)
  (let (definitions (filter shell-helper-definition?
                            (source-file-definitions file)))
    (and (>= (length definitions) +build-runtime-min-shell-helper-definitions+)
         (evidence-group
          "shell-helper-definitions"
          (length definitions)
          (definition-selector (car definitions))))))

;;; Boundary:
;;; - One launcher heredoc can contain several shell-only controls.
;;; - The marker total measures payload density across parser literals.
;;; - The group still needs a second independent signal before warning.
;;; Data flow:
;;; - filter keeps only call facts whose string arguments satisfy the marker
;;;   predicate, then a separate total scores marker density.
;;; Arity evidence:
;;; - call-has-shell-control-literal? consumes one CallFact.
;;; - shell-control-marker-total consumes the filtered CallFact list.
;;; Invariant:
;;; - Selector choice follows the first parser call fact.
;;; - Count only affects
;;;   evidence strength.
;;; Hidden invariant:
;;; - The evidence selector remains independent from the scoring pass.
;; MaybeEvidenceGroup <- SourceFile
(def (shell-control-literal-evidence file)
  (let* ((calls (filter call-has-shell-control-literal?
                        (source-file-calls file)))
         (count (shell-control-marker-total calls)))
    (and (>= count +build-runtime-min-shell-control-markers+)
         (evidence-group
          "shell-control-literals"
          count
          (call-fact-selector (car calls))))))

;;; Boundary:
;;; - build-support may write launcher/config files.
;;; - Writer calls become evidence only when their payload is shell control.
;;; - Plain display or write-string calls remain below the warning gate.
;;; Data flow:
;;; - filter applies one pure CallFact classifier before count and selector are
;;;   packaged into an EvidenceGroup.
;;; Arity evidence:
;;; - shell-writer-call? consumes one CallFact and returns a boolean.
;;; - The filtered list can be counted without reclassifying calls.
;;; Invariant:
;;; - Writer identity and shell-control payload must be true together.
;;; - Neither
;;;   condition alone is actionable.
;;; Hidden invariant:
;;; - Keeping the classifier separate prevents writer calls from bypassing the
;;;   shell-control payload check.
;; MaybeEvidenceGroup <- SourceFile
(def (shell-writer-call-evidence file)
  (let (calls (filter shell-writer-call? (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-writer-calls"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Boundary:
;;; - sh -c collapses typed argv into shell text.
;;; - list argv process calls remain the preferred runtime boundary.
;;; - This group is paired with payload evidence before a finding exists.
;;; Data flow:
;;; - filter extracts process calls that cross the sh -c boundary while leaving
;;;   argv-list calls outside the group.
;;; Arity evidence:
;;; - shell-dispatch-call? consumes one CallFact and returns a boolean.
;;; - The filter result keeps the source order used by call-fact-selector.
;;; Invariant:
;;; - The predicate is arity-stable over CallFact.
;;; - Selector order stays tied to
;;;   parser order.
;;; Hidden invariant:
;;; - A loop that stops on the first process call would miss later sh -c
;;;   evidence and under-report build pipeline drift.
;; MaybeEvidenceGroup <- SourceFile
(def (shell-dispatch-call-evidence file)
  (let (calls (filter shell-dispatch-call? (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-dispatch-call"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Pipeline literals refine sh -c evidence so build.ss warnings focus on
;;; pipeline orchestration instead of every shell invocation.
;; MaybeEvidenceGroup <- SourceFile
(def (shell-pipeline-literal-evidence file)
  (let (calls (filter shell-pipeline-literal-call? (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-pipeline-literal"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Scope guard: build-support files intentionally emit launcher/runtime
;;; wrappers, so they need a dedicated evidence profile.
;; Boolean <- SourceFile
(def (build-support-source-file? file)
  (let (path (source-file-path file))
    (and (string-prefix? "build-support/" path)
         (string-suffix? ".ss" path))))

;;; Scope guard: package build logic is checked for shell pipelines, not for
;;; launcher template text.
;; Boolean <- SourceFile
(def (package-build-file? file)
  (equal? (source-file-path file) "build.ss"))

;;; Naming markers catch helper families before they become an unbounded shell
;;; wrapper subsystem.
;; Boolean <- DefinitionFact
(def (shell-helper-definition? definition)
  (let (name (definition-name definition))
    (and (string? name)
         (ormap (lambda (marker)
                  (if (string-suffix? "-" marker)
                    (string-prefix? marker name)
                    (string-contains name marker)))
                +shell-helper-definition-markers+))))

;;; Boundary:
;;; - Parser-owned call arguments are the evidence boundary.
;;; - ormap keeps marker detection declarative across literal arguments.
;;; - The policy does not become a shell parser.
;;; Data flow:
;;; - filter removes non-string arguments, then ormap asks whether any remaining
;;;   literal carries a shell-control marker.
;;; Invariant:
;;; - Non-string parser arguments are ignored rather than coerced into shell
;;;   text.
;; Boolean <- CallFact
(def (call-has-shell-control-literal? call)
  (ormap string-has-shell-control-marker?
         (filter string? (call-fact-arguments call))))

;;; Writer calls become evidence only when their argument payload contains
;;; shell-control markers.
;; Boolean <- CallFact
(def (shell-writer-call? call)
  (and (member (call-fact-callee call) '("display" "write-string"))
       (call-has-shell-control-literal? call)))

;;; sh -c is the risk boundary because it collapses typed argv into shell text.
;; Boolean <- CallFact
(def (shell-dispatch-call? call)
  (and (member (call-fact-callee call) +shell-dispatch-callees+)
       (call-arguments-contain? call "sh")
       (call-arguments-contain? call "-c")))

;;; Pipeline literals separate incidental shell dispatch from build-pipeline
;;; orchestration.
;; Boolean <- CallFact
(def (shell-pipeline-literal-call? call)
  (and (shell-dispatch-call? call)
       (ormap (lambda (argument)
                (and (string? argument)
                     (ormap (cut string-contains argument <>)
                            +shell-pipeline-literal-markers+)))
              (call-fact-arguments call))))

;;; Argument containment stays string-only so parser facts, not shell parsing,
;;; own the evidence boundary.
;; Boolean <- CallFact String
(def (call-arguments-contain? call needle)
  (ormap (lambda (argument)
           (and (string? argument)
                (string-contains argument needle)))
         (call-fact-arguments call)))

;;; Boundary:
;;; - Marker matching is intentionally lexical and conservative.
;;; - ormap keeps the vocabulary data-owned instead of branch-owned.
;;; - Composite evidence decides whether lexical hits are actionable.
;;; Data flow:
;;; - ormap short-circuits over the configured marker vocabulary and returns a
;;;   boolean predicate for one string literal.
;;; Arity evidence:
;;; - cut specializes string-contains with the fixed text argument.
;;; - Each marker remains the second argument to string-contains.
;;; Invariant:
;;; - The marker list remains data.
;;; - Changing markers does not add branch logic.
;;; Hidden invariant:
;;; - Marker ordering affects only short-circuit cost, not evidence semantics.
;; Boolean <- String
(def (string-has-shell-control-marker? text)
  (ormap (cut string-contains text <>)
         +shell-control-literal-markers+))

;;; The total marker count measures payload density across calls, not just the
;;; number of calls.
;; Integer <- (List CallFact)
(def (shell-control-marker-total calls)
  (apply +
         (map call-shell-control-marker-count calls)))

;;; Per-call counts preserve density evidence when one generated launcher
;;; contains several shell-control markers.
;; Integer <- CallFact
(def (call-shell-control-marker-count call)
  (apply +
         (map string-shell-control-marker-count
              (filter string? (call-fact-arguments call)))))

;;; Boundary:
;;; - Literal marker count is a small evidence score.
;;; - filter keeps the marker vocabulary data-owned.
;;; - Counting remains advisory until another evidence group agrees.
;;; Data flow:
;;; - filter materializes the matched marker subset so length can score how
;;;   dense one generated literal is.
;;; Arity evidence:
;;; - cut again fixes the text argument and maps each marker through the same
;;;   string-contains predicate.
;;; Invariant:
;;; - The score is marker density only.
;;; - It never interprets shell grammar.
;;; Hidden invariant:
;;; - Counting the matched subset keeps scoring independent from marker order.
;; Integer <- String
(def (string-shell-control-marker-count text)
  (length
   (filter (cut string-contains text <>)
           +shell-control-literal-markers+)))

;;; Intentional raw data record:
;;; - EvidenceGroup is positional diagnostic data: name, count, selector.
;;; - Keeping it as a list avoids adding object-like records to a policy helper
;;;   module and keeps runtime semantics out of the policy evidence packet.
;; EvidenceGroup <- String Integer Selector
(def (evidence-group name count selector)
  (list name count selector))

;;; Accessors keep diagnostic packets opaque to policy callers.
;; String <- EvidenceGroup
(def (evidence-group-name group)
  (car group))

;;; Accessors keep diagnostic packets opaque to policy callers.
;; Integer <- EvidenceGroup
(def (evidence-group-count group)
  (cadr group))

;;; Accessors keep diagnostic packets opaque to policy callers.
;; Selector <- EvidenceGroup
(def (evidence-group-selector group)
  (caddr group))

;;; Findings should point at the strongest first evidence group when available,
;;; otherwise the file path is the fallback selector.
;; Selector <- SourceFile (List EvidenceGroup)
(def (build-runtime-evidence-selector file groups)
  (if (pair? groups)
    (evidence-group-selector (car groups))
    (source-file-path file)))

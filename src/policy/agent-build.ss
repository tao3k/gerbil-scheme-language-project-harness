;;; -*- Gerbil -*-
;;; Agent-facing package build responsibility policy.

(import :parser/facade
        :policy/model
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar cut filter filter-map find ormap)
        :types/findings)

(export package-build-responsibility-findings
        package-build-responsibility-finding)

;;; Marker set names command-routing responsibilities that must not live in
;;; the package-level build owner.
;; (List BuildRoutingMarker)
(def +package-build-runtime-routing-markers+
  '("search pattern"
    "search extension"
    "FAST_PATTERN"
    "FAST_EXTENSION"
    "\"${2:-}\" = pattern"
    "\"${2:-}\" = extension"))

;;; Wrapper/materializer definitions are CLI/provider-wrapper ownership, not
;;; package build ownership.
;; (List String)
(def +package-build-wrapper-definition-prefixes+
  '("write-gsc-wrapper"
    "write-native-"
    "write-provider-cli"
    "write-executable-script"))

;;; Boundary:
;;; - Only the package-root build.ss is governed here.
;;; - Wrapper templates and command owners may contain CLI routing elsewhere.
;; (List PackageBuildFinding) <- ProjectIndex
(def (package-build-responsibility-findings index)
  (let (file (package-top-level-build-file index))
    (if file
      (append
       (filter-map (cut package-build-responsibility-finding file <>)
                   (source-file-calls file))
       (filter-map (cut package-build-wrapper-definition-finding file <>)
                   (source-file-definitions file)))
      '())))

;;; Invariant:
;;; - The rule is intentionally scoped to gerbil.pkg beside build.ss.
;;; - Nested helper owners are outside this policy surface.
;; MaybePackageBuildFile <- ProjectIndex
(def (package-top-level-build-file index)
  (and (project-index-package index)
       (equal? (project-package-path (project-index-package index)) "gerbil.pkg")
       (find (lambda (file)
               (equal? (source-file-path file) "build.ss"))
             (project-index-files index))))

;;; Finding contract:
;;; - Evidence comes from parser-owned call arguments, not raw grep.
;;; - The repair path preserves build orchestration and moves CLI semantics.
;; MaybePackageBuildFinding <- PackageBuildFile CallFact
(def (package-build-responsibility-finding file call)
  (let (evidence (build-routing-call-evidence call))
    (and evidence
         (make-type-finding
          (policy-rule-id +agent-package-build-responsibility-rule+)
          (policy-rule-severity +agent-package-build-responsibility-rule+)
          (source-file-path file)
          "package-level build.ss contains CLI/search routing; keep build.ss as build spec/orchestration and move command semantics into src/cli, src/commands, or an explicit provider wrapper owner"
          (call-fact-selector call)
          (hash (evidence evidence)
                (kind "package-build-responsibility")
                (allowedBuildRole "build spec, dependency setup, compile orchestration, provider wrapper delegation")
                (disallowedRole "CLI/search/pattern routing policy or generated command semantics")
                (next "move routing to src/cli, src/commands/search, or build-support/provider-cli"))))))

;;; Finding contract:
;;; - Evidence comes from parser-owned definition names.
;;; - Top-level build.ss may delegate to wrapper owners but must not define
;;;   wrapper/script materializers itself.
;; MaybePackageBuildFinding <- PackageBuildFile DefinitionFact
(def (package-build-wrapper-definition-finding file definition)
  (let (name (definition-name definition))
    (and (package-build-wrapper-definition-name? name)
         (make-type-finding
          (policy-rule-id +agent-package-build-responsibility-rule+)
          (policy-rule-severity +agent-package-build-responsibility-rule+)
          (source-file-path file)
          "package-level build.ss defines provider wrapper/script materializers; keep build.ss as build spec/orchestration and move wrapper generation into build-support/provider-cli or the CLI owner"
          (definition-selector definition)
          (hash (evidence name)
                (kind "package-build-wrapper-definition")
                (allowedBuildRole "build spec, dependency setup, compile orchestration, provider wrapper delegation")
                (disallowedRole "provider wrapper/script generation or CLI executable materialization")
                (next "move wrapper generation to build-support/provider-cli or src/cli"))))))

;;; Evidence boundary:
;;; - String arguments are still parser facts.
;;; - The marker list names routing responsibilities that do not belong in build.ss.
;; MaybeBuildRoutingEvidence <- CallFact
(def (build-routing-call-evidence call)
  (find runtime-routing-text?
        (filter string? (call-fact-arguments call))))

;;; Predicate stays intentionally small so future markers extend the data table,
;;; not the control flow.
;; Boolean <- BuildRoutingEvidence
(def (runtime-routing-text? text)
  (ormap (cut string-contains text <>)
         +package-build-runtime-routing-markers+))

;;; Narrow name gate: only wrapper/script materializer families are blocked.
;;; Build helpers may still use ordinary write/compile verbs when they do not
;;; own generated command semantics.
;; Boolean <- MaybeString
(def (package-build-wrapper-definition-name? name)
  (and (string? name)
       (ormap (cut string-prefix? <> name)
              +package-build-wrapper-definition-prefixes+)
       (or (not (string-prefix? "write-native-" name))
           (string-contains name "wrapper"))))

;;; Local selector rendering keeps the finding tied to parser-owned definition
;;; ranges without adding another dependency to the policy surface.
;; Selector <- DefinitionFact
(def (definition-selector definition)
  (string-append (definition-path definition)
                 ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

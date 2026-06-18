;;; -*- Gerbil -*-
;;; Agent-facing package build responsibility policy.

(import :parser/facade
        :policy/model
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar cut filter filter-map find ormap)
        :types/findings)

(export package-build-responsibility-findings
        package-build-responsibility-finding
        package-build-canonical-shape-findings
        package-build-canonical-shape-finding)

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

;;; Native build surface observed in .data/gerbil build scripts:
;;; simple packages use :std/build-script/defbuild-script; intermediate
;;; scripts use :std/make/make over an explicit build spec.
;; (List ModuleName)
(def +package-build-native-build-modules+
  '(":std/build-script" ":std/make"))

;; (List IncludePath)
(def +package-build-provider-build-includes+
  '("build-support/provider-build.ss"))

;; (List CalleeName)
(def +package-build-spec-callees+
  '("defbuild-script" "make" "make-clean"))

;; (List CalleeName)
(def +package-build-manual-dispatch-callees+
  '("invoke" "run-process" "open-process"))

;; (List String)
(def +package-build-compiler-arguments+
  '("gxc" "gsc" "gxi" "cc" "gcc" "clang"))

;;; Boundary:
;;; - Only the package-root build.ss is governed here.
;;; - Wrapper templates and command owners may contain CLI routing elsewhere.
;; : (-> ProjectIndex (List PackageBuildFinding) )
(def (package-build-responsibility-findings index)
  (let (file (package-top-level-build-file index))
    (if file
      (append
       (filter-map (cut package-build-responsibility-finding file <>)
                   (source-file-calls file))
       (filter-map (cut package-build-wrapper-definition-finding file <>)
                   (source-file-definitions file)))
      '())))

;;; Boundary:
;;; - The package-root build.ss should expose Gerbil's native build surface.
;;; - Complex provider builds may still be intermediate scripts, but they must
;;;   route compilation through :std/make/make over a build spec.
;; : (-> ProjectIndex (List PackageBuildFinding) )
(def (package-build-canonical-shape-findings index)
  (let (file (package-top-level-build-file index))
    (if file
      (let (finding (package-build-canonical-shape-finding file))
        (if finding [finding] '()))
      '())))

;;; Invariant:
;;; - The rule is intentionally scoped to gerbil.pkg beside build.ss.
;;; - Nested helper owners are outside this policy surface.
;; : (-> ProjectIndex MaybePackageBuildFile )
(def (package-top-level-build-file index)
  (and (project-index-package index)
       (equal? (project-package-path (project-index-package index)) "gerbil.pkg")
       (find (lambda (file)
               (equal? (source-path-class (source-file-path file))
                       "package-build"))
             (project-index-files index))))

;;; Finding contract:
;;; - Import evidence comes from moduleImportFacts.
;;; - Entrypoint evidence comes from callFacts.
;;; - The rule does not read build.ss text or infer from file names.
;; : (-> PackageBuildFile MaybePackageBuildFinding )
(def (package-build-canonical-shape-finding file)
  (let* ((native-import
          (find package-build-native-build-import?
                (source-file-module-imports file)))
         (build-call
          (find package-build-spec-call?
                (source-file-calls file)))
         (manual-call
          (find package-build-manual-compiler-dispatch-call?
                (source-file-calls file)))
         (native-build-definition
          (find package-build-native-build-definition?
                (source-file-definitions file)))
         (provider-build-include
          (find package-build-provider-build-include?
                (source-file-includes file)))
         (main-definition
          (find package-build-main-definition?
                (source-file-definitions file))))
    (and (not (and native-import
                   (or build-call
                       native-build-definition
                       provider-build-include)))
         (make-type-finding
          (policy-rule-id +agent-package-build-canonical-shape-rule+)
          (policy-rule-severity +agent-package-build-canonical-shape-rule+)
          (source-file-path file)
          "package-level build.ss is not using the native Gerbil build-script/make shape; use (only-in :std/build-script defbuild-script) with defbuild-script for simple packages, or :std/make make/make-clean over an explicit build spec for intermediate scripts"
          (package-build-canonical-shape-selector
           file native-import build-call manual-call native-build-definition provider-build-include main-definition)
          (package-build-canonical-shape-details
           native-import build-call manual-call native-build-definition provider-build-include main-definition)))))

;; : (-> ModuleImportFact Boolean )
(def (package-build-native-build-import? fact)
  (member (module-import-fact-module fact)
          +package-build-native-build-modules+))

;;; Boundary:
;;; - Gerbil records `(apply make ...)` as an `apply` call whose first argument is "make".
;;; - Treat direct and apply-based make entries as the same native build-spec surface.
;;; - This keeps later compiler dispatch evidence from dominating a valid intermediate script.
;; : (-> CallFact Boolean )
(def (package-build-spec-call? call)
  (or (member (call-fact-callee call)
              +package-build-spec-callees+)
      (and (equal? (call-fact-callee call) "apply")
           (ormap package-build-spec-callee-name?
                  (filter string? (call-fact-arguments call))))))

;; : (-> String Boolean )
(def (package-build-spec-callee-name? argument)
  (member argument +package-build-spec-callees+))

;;; Definition surface:
;;; - Some build owners expose `make` through a helper rather than a top-level call fact.
;;; - Parser definition facts still prove the native build-spec boundary exists.
;;; - Keep the accepted names narrow so this does not bless arbitrary build helpers.
;; : (-> DefinitionFact Boolean )
(def (package-build-native-build-definition? definition)
  (member (definition-name definition)
          '("provider-build-spec" "make-provider!" "clean-provider!"
            "provider-build-stages" "provider-build-stage-ref"
            "run-provider-build-stage!")))

;; : (-> IncludePath Boolean )
(def (package-build-provider-build-include? include)
  (member include +package-build-provider-build-includes+))

;;; Risk boundary:
;;; - Compiler executables inside process calls are manual dispatch evidence.
;;; - The canonical-shape rule emits only when no native build-spec call is present.
;;; - Arguments stay parser-owned strings; this predicate does not parse shell text.
;; : (-> CallFact Boolean )
(def (package-build-manual-compiler-dispatch-call? call)
  (and (member (call-fact-callee call)
               +package-build-manual-dispatch-callees+)
       (ormap package-build-compiler-argument?
              (filter string? (call-fact-arguments call)))))

;;; Marker vocabulary:
;;; - These names identify compiler/process boundaries, not arbitrary path text.
;;; - Adding a compiler belongs in the data table above, not in branch logic here.
;; : (-> String Boolean )
(def (package-build-compiler-argument? argument)
  (ormap (cut string-contains argument <>)
         +package-build-compiler-arguments+))

;; : (-> DefinitionFact Boolean )
(def (package-build-main-definition? definition)
  (equal? (definition-name definition) "main"))

;; : (-> PackageBuildFile MaybeModuleImportFact MaybeCallFact MaybeCallFact MaybeDefinitionFact MaybeIncludePath MaybeDefinitionFact Selector )
(def (package-build-canonical-shape-selector file native-import build-call manual-call native-build-definition provider-build-include main-definition)
  (cond
   (manual-call (call-fact-selector manual-call))
   (main-definition (definition-selector main-definition))
   (native-build-definition (definition-selector native-build-definition))
   (build-call (call-fact-selector build-call))
   (native-import (package-build-module-import-selector native-import))
   (else (string-append (source-file-path file) ":1-1"))))

;;; Details keep source provenance explicit so an agent can repair toward the
;;; upstream Gerbil pattern rather than inventing a local mini build system.
;; : (-> MaybeModuleImportFact MaybeCallFact MaybeCallFact MaybeDefinitionFact MaybeIncludePath MaybeDefinitionFact PolicyDetails )
(def (package-build-canonical-shape-details native-import build-call manual-call native-build-definition provider-build-include main-definition)
  (hash (kind "package-build-canonical-shape")
        (nativeBuildImport
         (and native-import (module-import-fact-module native-import)))
        (nativeBuildImportModifier
         (and native-import (module-import-fact-modifier native-import)))
        (buildSpecEntrypoint
         (and build-call (call-fact-callee build-call)))
        (nativeBuildDefinition
         (and native-build-definition
              (definition-name native-build-definition)))
        (providerBuildInclude provider-build-include)
        (manualCompilerDispatch
         (and manual-call (call-fact-callee manual-call)))
        (handWrittenMain
         (and main-definition (definition-name main-definition)))
        (allowedShape
         "simple build.ss: (only-in :std/build-script defbuild-script) plus defbuild-script; intermediate build.ss: :std/make make/make-clean over an explicit build spec plus a small stage table for provider-specific commands")
        (compositionalBuildShape
         "use named stage descriptors for compile/full/native/test commands; each stage should delegate wrapper/runtime materialization to build-support or src owners")
        (downstreamRepairPattern
         "keep build.ss as the package build control plane, route compilation through defbuild-script or :std/make, and move command/runtime behavior into composable stage helpers")
        (disallowedShape
         "hand-written compiler/process orchestration, shell pipelines, or CLI/runtime routing that replaces defbuild-script, make build specs, or stage descriptors")
        (sourceEvidence
         [".data/gerbil/doc/reference/dev/build.md:20-60"
          ".data/gerbil/doc/reference/std/make.md:32-52"
          ".data/gerbil/src/std/build-script.ss:1-35"
          ".data/gerbil/src/lang/build.ss:1-20"])
        (nativeFactSource
         "parser-owned moduleImportFacts plus include facts, callFacts and definitionFacts")
        (next
         "replace manual compiler dispatch with defbuild-script or :std/make make/make-clean; for provider builds add a small stage table and keep wrapper/runtime generation delegated to build-support")))

;;; Finding contract:
;;; - Evidence comes from parser-owned call arguments, not raw grep.
;;; - The repair path preserves build orchestration and moves CLI semantics.
;; : (-> PackageBuildFile CallFact MaybePackageBuildFinding )
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
;; : (-> PackageBuildFile DefinitionFact MaybePackageBuildFinding )
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
;; : (-> CallFact MaybeBuildRoutingEvidence )
(def (build-routing-call-evidence call)
  (find runtime-routing-text?
        (filter string? (call-fact-arguments call))))

;;; Predicate stays intentionally small so future markers extend the data table,
;;; not the control flow.
;; : (-> BuildRoutingEvidence Boolean )
(def (runtime-routing-text? text)
  (ormap (cut string-contains text <>)
         +package-build-runtime-routing-markers+))

;;; Narrow name gate: only wrapper/script materializer families are blocked.
;;; Build helpers may still use ordinary write/compile verbs when they do not
;;; own generated command semantics.
;; : (-> MaybeString Boolean )
(def (package-build-wrapper-definition-name? name)
  (and (string? name)
       (ormap (cut string-prefix? <> name)
              +package-build-wrapper-definition-prefixes+)
       (or (not (string-prefix? "write-native-" name))
           (string-contains name "wrapper"))))

;;; Local selector rendering keeps the finding tied to parser-owned definition
;;; ranges without adding another dependency to the policy surface.
;; : (-> DefinitionFact Selector )
(def (definition-selector definition)
  (string-append (definition-path definition)
                 ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

;; : (-> ModuleImportFact Selector )
(def (package-build-module-import-selector fact)
  (string-append (module-import-fact-path fact)
                 ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))

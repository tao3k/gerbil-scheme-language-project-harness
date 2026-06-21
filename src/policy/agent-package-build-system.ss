;;; -*- Gerbil -*-
;;; Package-level build.ss custom build-system detection.

(import :parser/facade
        :policy/detection
        :policy/poo-source
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter hash ormap))

(export package-build-file?
        package-build-quality-detection-prototypes
        package-build-custom-system-result?)

;; (List GroupName)
(def +package-build-custom-system-required-groups+
  '("package-build-file"
    "missing-native-build-surface"
    "manual-build-orchestration"))

;; (List ModuleName)
(def +package-build-canonical-modules+
  '(":clan/building"))

;; (List ModuleName)
(def +package-build-std-build-script-modules+
  '(":std/build-script"))

;; (List ModuleName)
(def +package-build-std-make-modules+
  '(":std/make"))

;; (List CalleeName)
(def +package-build-canonical-environment-callees+
  '("init-build-environment!" "%set-build-environment!"))

;; (List CalleeName)
(def +package-build-std-build-script-callees+
  '("defbuild-script"))

;; (List CalleeName)
(def +package-build-std-make-callees+
  '("make"))

;; (List DefinitionName)
(def +package-build-std-make-spec-definitions+
  '("spec" "build-spec" "buildspec"))

;; (List IncludePath)
(def +package-build-std-make-spec-includes+
  '("build-spec.ss"))

;; (List CalleeName)
(def +package-build-canonical-enumerator-callees+
  '("all-gerbil-modules"))

;; (List CalleeName)
(def +package-build-manual-orchestration-callees+
  '("add-load-path!"
    "invoke"
    "open-process"
    "run-process"
    "setenv"
    "shell-command"
    "system"))

;; (List String)
(def +package-build-manual-orchestration-markers+
  '("GERBIL_LOADPATH"
    "gxc"
    "gsc"
    "gxi"
    "srcdir:"
    "-exe"
    "-static"
    "find src"))

;; (List String)
(def +package-build-shell-pipeline-literal-markers+
  '("|" "xargs" "find src" "sort |" " -P "))

;; (List CalleeName)
(def +package-build-shell-dispatch-callees+
  '("invoke" "run-process" "open-process"))

;;; Public detector surface:
;;; - Keep package build-system policy in one owner.
;;; - The caller decides when a SourceFile is in package-build scope.
;; : (-> (List DetectionPrototype))
(def (package-build-quality-detection-prototypes)
  [(package-build-custom-system-detection-prototype)
   (package-build-shell-pipeline-detection-prototype)])

;; : (-> DetectionResult Boolean)
(def (package-build-custom-system-result? result)
  (equal? (detection-result-prototype result)
          "package-build-custom-system-all-of"))

;;; Package build custom-system detection is deliberately all-of:
;;; missing canonical shape alone is R025, and manual orchestration alone can be
;;; a fixture.  Together they identify a downstream agent replacing gxpkg and
;;; canonical Gerbil build entrypoints with a local build control plane.
;; : (-> DetectionPrototype)
(def (package-build-custom-system-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "package-build-custom-system-all-of"
    'all-of
    [package-build-source-evidence
     package-build-missing-native-surface-evidence
     package-build-manual-orchestration-evidence]
    0
    +package-build-custom-system-required-groups+
    "package build custom-system drift requires scope, missing native build surface, and manual orchestration evidence")))

;;; Shell pipeline detection stays separate from the broader custom-system
;;; detector so sh -c pipeline repair remains precise.
;; : (-> DetectionPrototype)
(def (package-build-shell-pipeline-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "package-build-shell-pipeline-all-of"
    'all-of
    [package-build-shell-dispatch-call-evidence
     package-build-shell-pipeline-literal-evidence]
    0
    ["shell-dispatch-call" "shell-pipeline-literal"]
    "package build shell-pipeline drift requires dispatch and payload evidence")))

;;; Scope guard: only package-root build.ss is checked for custom build-system
;;; drift.  build-support runtime owners use a separate detector profile.
;; : (-> SourceFile Boolean)
(def (package-build-file? file)
  (equal? (source-path-class (source-file-path file))
          "package-build"))

;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-source-evidence file)
  (and (package-build-file? file)
       (evidence-group
        "package-build-file"
        1
        (source-file-root-selector file))))

;;; Negative evidence is explainable only because the all-of detector pairs it
;;; with positive manual orchestration evidence.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-missing-native-surface-evidence file)
  (and (package-build-file? file)
       (not (package-build-canonical-build-shape? file))
       (evidence-group
        "missing-native-build-surface"
        1
        (source-file-root-selector file))))

;;; Evidence boundary: keep only parser-owned calls that prove build.ss is
;;; coordinating compiler/process work instead of delegating to clan/building.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-manual-orchestration-evidence file)
  (let (calls (filter package-build-manual-orchestration-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "manual-build-orchestration"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Shell dispatch evidence stays separate from literal pipeline strings so
;;; command invocation and argument content can compose as independent signals.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-shell-dispatch-call-evidence file)
  (let (calls (filter package-build-shell-dispatch-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-dispatch-call"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Pipeline literals refine sh -c evidence so build.ss warnings focus on
;;; pipeline orchestration instead of every shell invocation.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-shell-pipeline-literal-evidence file)
  (let (calls (filter package-build-shell-pipeline-literal-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-pipeline-literal"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Canonical package build evidence stays structural: module imports prove
;;; clan/building is present, calls prove environment initialization, and either
;;; calls or definitions prove delegated source discovery.
;; : (-> SourceFile Boolean)
(def (package-build-canonical-build-shape? file)
  (or (package-build-canonical-clan-shape? file)
      (package-build-std-build-script-shape? file)
      (package-build-std-make-buildspec-shape? file)))

;;; Clan/building shape is the preferred package boundary: the import provides
;;; build semantics, init call owns environment setup, and enumerator/spec
;;; evidence proves source discovery is delegated instead of handwritten.
;; : (-> SourceFile Boolean)
(def (package-build-canonical-clan-shape? file)
  (and (ormap package-build-canonical-module-import?
              (source-file-module-imports file))
       (ormap package-build-canonical-environment-call?
              (source-file-calls file))
       (or (ormap package-build-canonical-enumerator-call?
                  (source-file-calls file))
           (ormap package-build-spec-definition?
                  (source-file-definitions file)))))

;;; std/build-script is accepted as a legacy structural witness only when the
;;; import and defbuild-script call appear together, keeping migration evidence
;;; distinct from arbitrary package-level compiler orchestration.
;; : (-> SourceFile Boolean)
(def (package-build-std-build-script-shape? file)
  (and (ormap package-build-std-build-script-module-import?
              (source-file-module-imports file))
       (ormap package-build-std-build-script-call?
              (source-file-calls file))))

;;; std/make compatibility requires both the make import and make call plus a
;;; parser-visible spec definition/include, so a loose make invocation does not
;;; become an accepted custom build system.
;; : (-> SourceFile Boolean)
(def (package-build-std-make-buildspec-shape? file)
  (and (ormap package-build-std-make-module-import?
              (source-file-module-imports file))
       (ormap package-build-std-make-call?
              (source-file-calls file))
       (or (ormap package-build-std-make-spec-definition?
                  (source-file-definitions file))
           (ormap package-build-std-make-spec-include?
                  (source-file-includes file)))))

;; : (-> ModuleImportFact Boolean)
(def (package-build-canonical-module-import? fact)
  (member (module-import-fact-module fact)
          +package-build-canonical-modules+))

;; : (-> ModuleImportFact Boolean)
(def (package-build-std-build-script-module-import? fact)
  (member (module-import-fact-module fact)
          +package-build-std-build-script-modules+))

;; : (-> ModuleImportFact Boolean)
(def (package-build-std-make-module-import? fact)
  (member (module-import-fact-module fact)
          +package-build-std-make-modules+))

;; : (-> CallFact Boolean)
(def (package-build-canonical-environment-call? call)
  (member (call-fact-callee call)
          +package-build-canonical-environment-callees+))

;; : (-> CallFact Boolean)
(def (package-build-std-build-script-call? call)
  (member (call-fact-callee call)
          +package-build-std-build-script-callees+))

;; : (-> CallFact Boolean)
(def (package-build-std-make-call? call)
  (member (call-fact-callee call)
          +package-build-std-make-callees+))

;; : (-> CallFact Boolean)
(def (package-build-canonical-enumerator-call? call)
  (member (call-fact-callee call)
          +package-build-canonical-enumerator-callees+))

;; : (-> DefinitionFact Boolean)
(def (package-build-spec-definition? definition)
  (equal? (definition-name definition) "spec"))

;; : (-> DefinitionFact Boolean)
(def (package-build-std-make-spec-definition? definition)
  (member (definition-name definition)
          +package-build-std-make-spec-definitions+))

;; : (-> IncludePath Boolean)
(def (package-build-std-make-spec-include? include)
  (member include +package-build-std-make-spec-includes+))

;;; Manual orchestration needs a build-owned callee or compiler/env marker.
;;; The marker table is policy data, so extending it does not add branch logic.
;; : (-> CallFact Boolean)
(def (package-build-manual-orchestration-call? call)
  (or (member (call-fact-callee call)
              +package-build-manual-orchestration-callees+)
      (ormap package-build-manual-orchestration-argument?
             (filter string? (call-fact-arguments call)))))

;;; Marker matching is a predicate family: cut/ormap express any orchestration
;;; marker hit without turning the package-build rule into an open-coded branch.
;; : (-> String Boolean)
(def (package-build-manual-orchestration-argument? argument)
  (ormap (cut string-contains argument <>)
         +package-build-manual-orchestration-markers+))

;;; sh -c is the risk boundary because it collapses typed argv into shell text.
;; : (-> CallFact Boolean)
(def (package-build-shell-dispatch-call? call)
  (and (member (call-fact-callee call)
               +package-build-shell-dispatch-callees+)
       (call-arguments-contain? call "sh")
       (call-arguments-contain? call "-c")))

;;; Nested argument scanning requires the shell dispatcher and pipeline literal
;;; to be on the same parsed call, which is stricter than source text matching.
;; : (-> CallFact Boolean)
(def (package-build-shell-pipeline-literal-call? call)
  (and (package-build-shell-dispatch-call? call)
       (ormap (lambda (argument)
                (and (string? argument)
                     (ormap (cut string-contains argument <>)
                            +package-build-shell-pipeline-literal-markers+)))
              (call-fact-arguments call))))

;;; Shared argument containment keeps signal logic data-driven: callers provide
;;; the marker, while parser-owned argument values remain the evidence boundary.
;; : (-> CallFact String Boolean)
(def (call-arguments-contain? call needle)
  (ormap (lambda (argument)
           (and (string? argument)
                (string-contains argument needle)))
         (call-fact-arguments call)))

;; : (-> SourceFile Selector)
(def (source-file-root-selector file)
  (string-append (source-file-path file) ":1-1"))

(policyScenario
 (id "package-build-canonical-shape")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R025"
    "build.ss"
    "build.ss:7-7"
    "package-level build.ss is not using the native Gerbil build-script/make shape; use (only-in :std/build-script defbuild-script) with defbuild-script for simple packages, or :std/make make/make-clean over an explicit build spec for intermediate scripts"))
  (buildShape
   ((kind "package-build-canonical-shape")
    (nativeBuildImport #f)
    (nativeBuildImportModifier #f)
    (buildSpecEntrypoint #f)
    (manualCompilerDispatch "invoke")
    (handWrittenMain "main")
    (allowedShape "simple build.ss: (only-in :std/build-script defbuild-script) plus defbuild-script; intermediate build.ss: :std/make make/make-clean over an explicit build spec")
    (disallowedShape "hand-written compiler/process orchestration that replaces defbuild-script or make build specs")
    (sourceEvidence
     (".data/gerbil/doc/reference/dev/build.md:20-60"
      ".data/gerbil/doc/reference/std/make.md:32-52"
      ".data/gerbil/src/std/build-script.ss:1-35"
      ".data/gerbil/src/lang/build.ss:1-20"))
    (nativeFactSource "parser-owned moduleImportFacts plus callFacts and definitionFacts")
    (next "replace manual compiler dispatch with defbuild-script or :std/make make/make-clean; keep provider wrapper generation delegated to build-support"))))
 (after
  (r025Findings ())))

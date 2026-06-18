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
    (providerBuildInclude #f)
    (manualCompilerDispatch "invoke")
    (handWrittenMain "main")
    (allowedShape "simple build.ss: (only-in :std/build-script defbuild-script) plus defbuild-script; intermediate build.ss: :std/make make/make-clean over an explicit build spec plus a small stage table for provider-specific commands")
    (compositionalBuildShape "use named stage descriptors for compile/full/native/test commands; each stage should delegate wrapper/runtime materialization to build-support or src owners")
    (downstreamRepairPattern "keep build.ss as the package build control plane, route compilation through defbuild-script or :std/make, and move command/runtime behavior into composable stage helpers")
    (disallowedShape "hand-written compiler/process orchestration, shell pipelines, or CLI/runtime routing that replaces defbuild-script, make build specs, or stage descriptors")
    (sourceEvidence
     (".data/gerbil/doc/reference/dev/build.md:20-60"
      ".data/gerbil/doc/reference/std/make.md:32-52"
      ".data/gerbil/src/std/build-script.ss:1-35"
      ".data/gerbil/src/lang/build.ss:1-20"))
    (nativeFactSource "parser-owned moduleImportFacts plus include facts, callFacts and definitionFacts")
    (next "replace manual compiler dispatch with defbuild-script or :std/make make/make-clean; for provider builds add a small stage table and keep wrapper/runtime generation delegated to build-support"))))
 (after
  (r025Findings ())))

(policyScenario
 (id "package-build-canonical-shape")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R025"
    "build.ss"
    "build.ss:9-9"
    "package-level build.ss is not using the canonical clan/building shape; import :clan/building, define spec with all-gerbil-modules, call init-build-environment!, and do not hand-write srcdir or GERBIL_LOADPATH"))
  (buildShape
   ((kind "package-build-canonical-shape")
    (nativeBuildImport #f)
    (nativeBuildImportModifier #f)
    (legacyBuildImport ":std/make")
    (buildSpecEntrypoint #f)
    (moduleEnumerator #f)
    (nativeBuildDefinition #f)
    (providerBuildInclude #f)
    (manualEnvironmentSetup "make")
    (manualCompilerDispatch "invoke")
    (handWrittenMain "main")
    (allowedShape "canonical build.ss: import :clan/building, define spec with all-gerbil-modules, include reusable t/unit helpers in spec when tests import them, and call init-build-environment!")
    (compositionalBuildShape "use clan/building for source discovery/load path and named stage descriptors only for provider-specific compile/full/native/test commands")
    (downstreamRepairPattern "keep build.ss as the package build control plane, route package compilation through init-build-environment!, and move command/runtime behavior into composable stage helpers")
    (disallowedShape "hand-written srcdir/loadpath setup, manual compiler/process orchestration, shell pipelines, or CLI/runtime routing that replaces clan/building")
    (sourceEvidence
     (".data/gerbil-utils/building.ss:1-120"
      ".data/gerbil-poo/build.ss:1-18"
      ".data/gerbil/doc/reference/std/make.md:32-52"))
    (nativeFactSource "parser-owned moduleImportFacts plus include facts, callFacts and definitionFacts")
    (next "replace manual compiler/loadpath/srcdir setup with :clan/building, all-gerbil-modules, and init-build-environment!; for provider builds keep wrapper/runtime generation delegated to build-support"))))
 (after
  (r025Findings ())))

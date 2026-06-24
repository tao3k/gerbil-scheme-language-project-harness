(policyScenario
 (id "package-build-canonical-shape")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R025"
    "build.ss"
    "build.ss:9-9"
    "package-level build.ss contains forbidden build control; do not hand-write GERBIL_LOADPATH/srcdir setup, manual compiler dispatch, defbuild-script package scripts, or runtime routing in build.ss"))
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
    (allowedShape "canonical build.ss: let clan/building own source discovery and load path setup; direct or only-in :clan/building imports are both valid, and top-level init-build-environment! is the package entrypoint")
    (compositionalBuildShape "use clan/building for source discovery/load path, keep package tests on Gerbil's gxtest runner, and call provider CLI commands through the compiled package module")
    (downstreamRepairPattern "keep build.ss as the package build control plane, route package compilation through clan/building, and keep command/runtime behavior in src/cli and src/commands")
    (disallowedShape "hand-written srcdir/loadpath setup, manual compiler/process orchestration, shell pipelines, or CLI/runtime routing that replaces clan/building")
    (sourceEvidence
     (".data/gerbil-utils/building.ss:1-120"
      ".data/gerbil-poo/build.ss:1-18"
      "gerbil://doc/reference/std/make.md:32-52"))
    (nativeFactSource "parser-owned moduleImportFacts plus include facts, callFacts and definitionFacts")
    (next "remove manual compiler/loadpath/srcdir or defbuild-script control from build.ss; keep package build initialization on clan/building and route runtime commands through compiled package modules"))))
 (after
  (r025Findings ())))

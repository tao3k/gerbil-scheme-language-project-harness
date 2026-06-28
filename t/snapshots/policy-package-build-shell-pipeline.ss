(policyScenario
 (id "package-build-shell-pipeline")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-020"
                   "build.ss"
                   "build.ss:1-1"
                   "package-level build.ss is drifting into a hand-written build system; keep build.ss on gxpkg plus clan/building, std/build-script, or std/make build-spec and move command/runtime behavior into package modules"))
         (runtimeQuality
          ((kind "package-build-custom-system")
           (detectionCombiner "package-build-custom-system-all-of")
           (detectionCombinerKind "all-of")
           (detectionSourcePattern "poo-prototype-composition")
           (requiredGroups
            ("package-build-file"
             "missing-native-build-surface"
             "manual-build-orchestration"))
           (evidenceGroups
            ("package-build-file"
             "missing-native-build-surface"
             "manual-build-orchestration"))
           (evidenceCounts (1 1 2))
           (allowedShape
            "package build delegates to a native Gerbil surface: gxpkg plus :clan/building for src-root discovery, :std/build-script for simple package templates, or :std/make build-spec for ssi:/gsc:/FFI/native build forms")
           (disallowedShape
            "hand-written compiler dispatch, GERBIL_LOADPATH/source-root management, or local mini build orchestration inside build.ss")
           (next "replace the local build system with :clan/building plus all-gerbil-modules for src-root packages, :std/build-script defbuild-script for simple gxpkg packages, or :std/make build-spec for ssi:/gsc:/FFI builds; keep CLI commands in src/cli or src/commands"))))
 (after (r020Findings
         (("GERBIL-SCHEME-AGENT-POLICY-020"
           "build.ss"
           "build.ss:1-1"
           "package-level build.ss is drifting into a hand-written build system; keep build.ss on gxpkg plus clan/building, std/build-script, or std/make build-spec and move command/runtime behavior into package modules")))))

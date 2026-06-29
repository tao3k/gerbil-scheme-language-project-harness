(policyScenario
 (id "build-runtime-shell-template")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-020"
                   "src/build-api/provider-cli.ss"
                   "src/build-api/provider-cli.ss:2-3"
                   "build/runtime support code is drifting back to shell-template or sh -c pipeline orchestration; use Gerbil runtime sources, std/misc/process, list command arguments, and small launcher/config writers"))
         (runtimeQuality
          ((kind "build-runtime-quality")
           (detectionCombiner "build-runtime-shell-template-composite")
           (detectionCombinerKind "threshold")
           (detectionSourcePattern "poo-prototype-composition")
           (requiredGroups ())
           (evidenceGroups
            ("shell-helper-definitions"
             "shell-control-literals"
             "shell-writer-calls"))
           (evidenceCounts (2 8 2))
           (allowedShape
            "Gerbil runtime wrapper source plus list command arguments")
           (disallowedShape "generated shell templates or sh -c pipelines")
           (next "move behavior into build/runtime source modules or normal Gerbil helpers; keep launchers as data/config writers"))))
 (after (r020Findings ())))

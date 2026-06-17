(policyScenario
 (id "package-build-shell-pipeline")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R020"
    "build.ss"
    "build.ss:3-3"
    "build/runtime support code is drifting back to shell-template or sh -c pipeline orchestration; use Gerbil runtime sources, std/misc/process, list command arguments, and small launcher/config writers"))
  (runtimeQuality
   ((kind "build-runtime-quality")
    (detectionCombiner "package-build-shell-pipeline-all-of")
    (detectionCombinerKind "all-of")
    (detectionSourcePattern "poo-prototype-composition")
    (requiredGroups
     ("shell-dispatch-call"
      "shell-pipeline-literal"))
    (evidenceGroups
     ("shell-dispatch-call"
      "shell-pipeline-literal"))
    (evidenceCounts (1 1))
    (allowedShape "Gerbil runtime wrapper source plus list command arguments")
    (disallowedShape "generated shell templates or sh -c pipelines")
    (next "move behavior into build-support/*-runtime.ss or normal Gerbil helpers; keep launchers as data/config writers"))))
 (after
  (r020Findings ())))

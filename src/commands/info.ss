;;; -*- Gerbil -*-
;;; Machine-readable harness info and verification receipt.

(import :constants
        :parser/facade
        :policy/catalog
        :protocol/json
        :support/args)

(export info-main
        info-packet
        display-info-packet)
;; String
(def +info-schema-id+
  "agent.semantic-protocols.gerbil-scheme-harness-info")
;; JsonPacket <- String
(def (info-packet root)
  (let* ((index (collect-project root))
         (package (project-index-package index)))
    (hash (schemaId +info-schema-id+)
          (schemaVersion "1")
          (languageId +language-id+)
          (providerId +provider-id+)
          (projectRoot root)
          (files (length (project-index-files index)))
          (definitions (length (project-definitions index)))
          (package (package-info-json package))
          (configurableInterface (configurable-interface-json))
          (agentSteering (agent-steering-json))
          (closureCommands (closure-commands-json)))))
;; Json <- Package
(def (package-info-json package)
  (and package
       (hash (path (project-package-path package))
             (name (project-package-name package))
             (packageManager (project-package-manager package))
             (dependencies (project-package-dependencies package)))))
;; Json
(def (configurable-interface-json)
  (hash (sourceScope
         (hash (owner "gerbil.pkg policy")
               (fields ["roots" "runtime-roots" "exclude-directories" "explanation"])
               (buildFallback
                "build.ss defbuild-script targets provide runtimeRoots when explicit source-scope is absent")))
        (agentPolicy
         (hash (owner "gerbil.pkg policy")
               (fields ["enabled-rules" "disabled-rules"])))))
;; Json
(def (agent-steering-json)
  (hash (facts (agent-steering-facts))
        (rules (agent-steering-rule-json))))
;; Json
(def (closure-commands-json)
  (hash (selfApply "GERBIL_LOADPATH=src:t gxtest -v t/self-apply-test.ss")
        (check "./bin/gerbil-scheme-harness check .")
        (bench "./bin/gerbil-scheme-harness bench --iterations 1 --max-total-ms 60000 .")))
;; JsonPacket <- Packet
(def (display-info-packet packet)
  (displayln "[gerbil-info] language=" (hash-get packet 'languageId)
             " provider=" (hash-get packet 'providerId)
             " files=" (hash-get packet 'files)
             " definitions=" (hash-get packet 'definitions))
  (let (package (hash-get packet 'package))
    (when package
      (displayln "|package path=" (hash-get package 'path)
                 " name=" (hash-get package 'name)
                 " manager=" (hash-get package 'packageManager))))
  (displayln "|interface source-scope=gerbil.pkg-policy fields=roots,runtime-roots,exclude-directories explanation=required-for-overrides")
  (displayln "|interface build-scope=build.ss defbuild-script targets -> runtime-roots when explicit source-scope is absent")
  (displayln "|interface agent-policy=gerbil.pkg-policy fields=enabled-rules,disabled-rules")
  (displayln "|agent-steering facts=macroFacts,bindingFacts,pooFormFacts,higherOrderFacts,controlFlowFacts,dependencyUsageFacts")
  (displayln "|agent-steering rules=" (agent-steering-rule-id-string))
  (let (closure (hash-get packet 'closureCommands))
    (displayln "|closure self-apply=" (hash-get closure 'selfApply))
    (displayln "|closure check=" (hash-get closure 'check))
    (displayln "|closure bench=" (hash-get closure 'bench))))
;; InfoMain <- (List XX)
(def (info-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (packet (info-packet root)))
    (if json?
      (write-json-line packet)
      (display-info-packet packet))
    0))

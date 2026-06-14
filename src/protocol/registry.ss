;;; -*- Gerbil -*-
;;; Provider registry projection.

(import :constants
        :parser/facade
        :std/sugar)

(export language-registry)
;;; Boundary:
;;; - language-registry coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; LanguageRegistry <- String
(def (language-registry root)
  (hash
   (registryId "agent.semantic-protocols.semantic-language-registry")
   (registryVersion "1")
   (protocolId "agent.semantic-protocols.semantic-language")
   (protocolVersion "1")
   (languages
    [(hash
      (languageId +language-id+)
      (providerId +provider-id+)
      (binary "gerbil-scheme-harness")
      (execution "external-process")
      (namespace "agent.semantic-protocols.languages.gerbil-scheme.gerbil-scheme-harness")
      (displayName +display-name+)
      (packageRoots [root])
      (methods ["search/prime" "search/owner" "search/fzf" "search/ingest"
                "search/pattern" "search/runtime-source" "search/compare"
                "index/structural" "index/native-syntax-owner-facts"
                "query/direct-source-read" "check/changed" "guide" "info"
                "evidence/graph" "evidence/analyze"])
      (schemas [(hash (schemaId "agent.semantic-protocols.semantic-extension-pattern-mapping")
                      (schemaVersion "1")
                      (path "schemas/semantic-extension-pattern-mapping.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-info")
                      (schemaVersion "1")
                      (path "schemas/semantic-gerbil-scheme-harness-info.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.semantic-runtime-source-acquisition")
                      (schemaVersion "1")
                      (path "schemas/semantic-runtime-source-acquisition.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.semantic-compare-packet")
                      (schemaVersion "1")
                      (path "schemas/semantic-compare-packet.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.semantic-structural-index")
                      (schemaVersion "1")
                      (path "schemas/semantic-structural-index.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.semantic-native-syntax-fact-index")
                      (schemaVersion "1")
                      (path "schemas/semantic-native-syntax-fact-index.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.semantic-evidence-graph")
                      (schemaVersion "1")
                      (path "schemas/semantic-evidence-graph.v1.schema.json"))
                (hash (schemaId "agent.semantic-protocols.semantic-graph-turbo-request")
                      (schemaVersion "1")
                      (path "schemas/semantic-graph-turbo-request.v1.schema.json"))])
      (methodDescriptors
       [(hash (method "info")
              (command "info")
              (summary "Emit provider-local Gerbil package, configurable interface, agent steering, and closure command facts.")
              (outputSchemaIds ["agent.semantic-protocols.gerbil-scheme-harness-info"]))
        (hash (method "search/pattern")
              (command "search pattern")
              (summary "Emit extension-backed executable pattern mappings for agent-facing framework or language usage guidance.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-extension-pattern-mapping"]))
        (hash (method "search/runtime-source")
              (command "search runtime-source")
              (summary "Emit active-runtime-to-source acquisition facts before answering version-sensitive language or runtime-boundary questions.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-runtime-source-acquisition"]))
        (hash (method "search/compare")
              (command "search compare")
              (summary "Compare active runtime facts with documented or remembered claims before version-sensitive guidance.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-compare-packet"]))
        (hash (method "index/structural")
              (command "search structural --json")
              (summary "Emit a lightweight native-parser structural interface; ASP Rust owns full index construction, graph topology, caching, and refresh planning.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-structural-index"]))
        (hash (method "index/native-syntax-owner-facts")
              (command "search structural --owner <path> --json")
              (summary "Emit owner-bounded native syntax facts for ASP-side fan-out and incremental structural indexing.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-native-syntax-fact-index"]))
        (hash (method "evidence/graph")
              (command "evidence")
              (summary "Emit a portable semantic evidence graph for Gerbil Scheme provider evidence.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-evidence-graph"]))
        (hash (method "evidence/analyze")
              (command "evidence")
              (summary "Emit a graph-turbo request for evidence-quality ranking.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-graph-turbo-request"]))])
      (source (hash
               (defaultExtensions +source-extensions+)
               (defaultConfigFiles +config-files+)
               (defaultSourceRoots ["src" "test" "tests" "doc" "docs" "examples" "tutorial"])
               (defaultIgnoredPathPrefixes +ignored-dirs+))))])))

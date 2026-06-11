;;; -*- Gerbil -*-
;;; Provider registry projection.

(import :constants
        :parser)

(export language-registry)

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
                "query/direct-source-read" "check/changed" "guide"])
      (source (hash
               (defaultExtensions +source-extensions+)
               (defaultConfigFiles +config-files+)
               (defaultSourceRoots ["src" "test" "tests" "doc" "docs" "examples" "tutorial"])
               (defaultIgnoredPathPrefixes +ignored-dirs+))))])))

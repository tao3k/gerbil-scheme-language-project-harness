(registry
 (registryId "agent.semantic-protocols.semantic-language-registry")
 (registryVersion "1")
 (languageId "gerbil-scheme")
 (providerId "gerbil-scheme-harness")
 (methods ("search/prime"
           "search/owner"
           "search/fzf"
           "search/ingest"
           "search/pattern"
           "search/runtime-source"
           "search/compare"
           "index/structural"
           "query/direct-source-read"
           "check/changed"
           "guide"
           "evidence/graph"
           "evidence/analyze"))
 (schemas
  ((schema
    (schemaId "agent.semantic-protocols.semantic-extension-pattern-mapping")
    (schemaVersion "1")
    (path "schemas/semantic-extension-pattern-mapping.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-runtime-source-acquisition")
    (schemaVersion "1")
    (path "schemas/semantic-runtime-source-acquisition.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-compare-packet")
    (schemaVersion "1")
    (path "schemas/semantic-compare-packet.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-structural-index")
    (schemaVersion "1")
    (path "schemas/semantic-structural-index.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-evidence-graph")
    (schemaVersion "1")
    (path "schemas/semantic-evidence-graph.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-graph-turbo-request")
    (schemaVersion "1")
    (path "schemas/semantic-graph-turbo-request.v1.schema.json"))))
 (methodDescriptors
  ((methodDescriptor
    (method "search/pattern")
    (command "search pattern")
    (outputSchemaIds ("agent.semantic-protocols.semantic-extension-pattern-mapping")))
   (methodDescriptor
    (method "search/runtime-source")
    (command "search runtime-source")
    (outputSchemaIds ("agent.semantic-protocols.semantic-runtime-source-acquisition")))
   (methodDescriptor
    (method "search/compare")
    (command "search compare")
    (outputSchemaIds ("agent.semantic-protocols.semantic-compare-packet")))
   (methodDescriptor
    (method "index/structural")
    (command "search structural --json")
    (outputSchemaIds ("agent.semantic-protocols.semantic-structural-index")))
   (methodDescriptor
    (method "evidence/graph")
    (command "evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-evidence-graph")))
   (methodDescriptor
    (method "evidence/analyze")
    (command "evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-graph-turbo-request"))))))

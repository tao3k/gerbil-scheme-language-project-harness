;;; -*- Gerbil -*-
;;; Project constants shared by command and protocol modules.

(export +language-id+
        +cli-id+
        +provider-id+
        +release-version+
        +semantic-extension-pattern-mapping-schema-id+
        +display-name+
        +help+)
;; String
(def +language-id+ "gerbil-scheme")
;; String
(def +cli-id+ "gslph")
;; String
(def +provider-id+ "gerbil-scheme-harness")
;; String
(def +release-version+ "v0.1.0-67-g20798be")
;; String
(def +semantic-extension-pattern-mapping-schema-id+
  "agent.semantic-protocols.semantic-extension-pattern-mapping")
;; Unit
(def +display-name+ "Gerbil Scheme Harness")
;; ConfigConstant
(def +help+
  "gslph - Gerbil Scheme semantic search and project harness

Usage:
  gslph search <view> ... [--json] [--code] [PROJECT_ROOT]
  gslph search workspace-scope [--json] [PROJECT_ROOT]
  gslph query <owner-path> --term <symbol> [--term <symbol>] [--workspace PROJECT_ROOT] [--names-only | --code]
  gslph query --from-hook direct-source-read --selector <workspace-path:start-end> --workspace PROJECT_ROOT --code
  gslph check [--changed] [--json] [--whitelist PATH] [PROJECT_ROOT]
  gslph fmt [--check] [--json] [--workspace PROJECT_ROOT] [PATH ...]
  gslph bench [--json] [--iterations N] [--max-total-ms N] [--max-interface-ms N] [--whitelist PATH] [PROJECT_ROOT]
  gslph evidence graph [--json] [PROJECT_ROOT]
  gslph evidence analyze [--json] [PROJECT_ROOT]
  gslph agent doctor [--json] [PROJECT_ROOT]
  gslph agent guide [PROJECT_ROOT]
  gslph info [--json] [PROJECT_ROOT]
")

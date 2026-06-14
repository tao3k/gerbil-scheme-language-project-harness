;;; -*- Gerbil -*-
;;; Provider constants shared by command and protocol modules.

(export +language-id+
        +provider-id+
        +semantic-extension-pattern-mapping-schema-id+
        +display-name+
        +help+)
;; String
(def +language-id+ "gerbil-scheme")
;; String
(def +provider-id+ "gerbil-scheme-harness")
;; String
(def +semantic-extension-pattern-mapping-schema-id+
  "agent.semantic-protocols.semantic-extension-pattern-mapping")
;; Unit
(def +display-name+ "Gerbil Scheme Harness")
;; ConfigConstant
(def +help+
  "gerbil-scheme-harness - Gerbil Scheme semantic search and project harness

Usage:
  gerbil-scheme-harness search <view> ... [--json] [--code] [PROJECT_ROOT]
  gerbil-scheme-harness query <owner-path> --term <symbol> [--term <symbol>] [--workspace PROJECT_ROOT] [--names-only | --code]
  gerbil-scheme-harness query --from-hook direct-source-read --selector <workspace-path:start-end> --workspace PROJECT_ROOT --code
  gerbil-scheme-harness check [--changed | --full] [--json] [--whitelist PATH] [PROJECT_ROOT]
  gerbil-scheme-harness bench [--json] [--iterations N] [--max-total-ms N] [--max-interface-ms N] [--whitelist PATH] [PROJECT_ROOT]
  gerbil-scheme-harness evidence graph [--json] [PROJECT_ROOT]
  gerbil-scheme-harness evidence analyze [--json] [PROJECT_ROOT]
  gerbil-scheme-harness agent doctor [--json] [PROJECT_ROOT]
  gerbil-scheme-harness agent guide [PROJECT_ROOT]
  gerbil-scheme-harness info [--json] [PROJECT_ROOT]
")

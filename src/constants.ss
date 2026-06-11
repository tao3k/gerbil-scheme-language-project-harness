;;; -*- Gerbil -*-
;;; Provider constants shared by command and protocol modules.

(export +language-id+
        +provider-id+
        +display-name+
        +help+)

(def +language-id+ "gerbil-scheme")
(def +provider-id+ "gerbil-scheme-harness")
(def +display-name+ "Gerbil Scheme Harness")

(def +help+
  "gerbil-scheme-harness - Gerbil Scheme semantic search and project harness

Usage:
  gerbil-scheme-harness search <view> ... [--json] [--code] [PROJECT_ROOT]
  gerbil-scheme-harness query <owner-path> --term <symbol> [--term <symbol>] [--workspace PROJECT_ROOT] [--names-only | --code]
  gerbil-scheme-harness query --from-hook direct-source-read --selector <workspace-path:start-end> --workspace PROJECT_ROOT --code
  gerbil-scheme-harness check [--changed | --full] [--json] [--whitelist PATH] [PROJECT_ROOT]
  gerbil-scheme-harness agent doctor [--json] [PROJECT_ROOT]
  gerbil-scheme-harness agent guide [PROJECT_ROOT]
")

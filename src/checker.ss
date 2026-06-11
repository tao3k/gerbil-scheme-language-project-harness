;;; -*- Gerbil -*-
;;; Stable checker facade for the Gerbil Scheme project harness.

(import :checker/core)

(export finding-rule-id
        finding-severity
        finding-path
        finding-message
        finding-selector
        finding-details
        project-status
        run-checks
        source-file-findings)

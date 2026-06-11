;;; -*- Gerbil -*-
;;; Stable facade for Gerbil package-manager facts.

(import :package-manager/core)

(export +gerbil-package-manager-id+
        project-package-managed-by-gerbil?
        project-package-activates?)

;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Type-check finding model.

(export make-type-finding
        type-finding-rule-id
        type-finding-severity
        type-finding-path
        type-finding-message
        type-finding-selector
        type-finding-details)
;; TypeFindingStruct
(defstruct type-finding (rule-id severity path message selector details))

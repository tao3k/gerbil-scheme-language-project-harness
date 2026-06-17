;;; -*- Gerbil -*-
(package: sample/poo-slot-cache-inheritance)

(.def root-cache
  version: 1
  label: "root")

(.def (left-cache @ [root-cache])
  version: => + 1
  branch: "left")

(.def (right-cache @ [root-cache])
  label: => string-append "-right"
  branch: "right")

(.def (cache-node @ [left-cache right-cache])
  stable: ? "missing"
  inherited-count: => + 1
  cached-child: =>.+ (.o value: 10)
  (super-label (next-method))
  local-cache: (compute-cache self))

;; SlotValue <- Object SlotSpec Superfun
(def (slot-cache-boundary self spec superfun)
  (.ref self 'stable)
  (.ref/cached self 'stable "missing")
  (apply-slot-spec spec self superfun))

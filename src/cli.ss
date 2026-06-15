;;; -*- Gerbil -*-
;;; Thin command dispatcher for the Gerbil Scheme project harness.

(import (only-in :commands/agent agent-main)
        (only-in :commands/bench bench-main)
        (only-in :commands/check check-main)
        (only-in :commands/evidence evidence-main)
        (only-in :commands/guide guide-main)
        (only-in :commands/info info-main)
        (only-in :commands/query query-main)
        (only-in :commands/search search-main)
        (only-in :constants +help+))
(export main)
;;; Invariant:
;;; - main owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Main <- (List XX)
(def (main . args)
  (match args
    ([] (display +help+) 0)
    (["-h"] (display +help+) 0)
    (["--help"] (display +help+) 0)
    (["help"] (display +help+) 0)
    (["search" . rest] (search-main rest))
    (["query" . rest] (query-main rest))
    (["check" . rest] (check-main rest))
    (["bench" . rest] (bench-main rest))
    (["evidence" . rest] (evidence-main rest))
    (["agent" . rest] (agent-main rest))
    (["guide" . rest] (guide-main rest))
    (["info" . rest] (info-main rest))
    (else
     (display +help+)
     2)))

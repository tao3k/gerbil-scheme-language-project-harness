;;; -*- Gerbil -*-
;;; Thin command dispatcher for the Gerbil Scheme project harness.

(import :commands/agent
        :commands/check
        :commands/guide
        :commands/query
        :commands/search
        :constants)
(export main)

(def (main . args)
  (match args
    ([] (display +help+) 0)
    (["-h"] (display +help+) 0)
    (["--help"] (display +help+) 0)
    (["help"] (display +help+) 0)
    (["search" . rest] (search-main rest))
    (["query" . rest] (query-main rest))
    (["check" . rest] (check-main rest))
    (["agent" . rest] (agent-main rest))
    (["guide" . _] (print-guide) 0)
    (else
     (display +help+)
     2)))

;;; -*- Gerbil -*-

(import :commands/agent)
(export main)

(def (main . args)
  (agent-main args))

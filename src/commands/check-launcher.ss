;;; -*- Gerbil -*-

(import :commands/check)
(export main)

(def (main . args)
  (check-main args))

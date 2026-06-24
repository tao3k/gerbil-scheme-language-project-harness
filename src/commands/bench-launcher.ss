;;; -*- Gerbil -*-

(import :commands/bench)
(export main)

(def (main . args)
  (bench-main args))

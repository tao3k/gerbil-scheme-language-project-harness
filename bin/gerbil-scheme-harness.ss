;; -*- Gerbil -*-
(import :gerbil/gambit
        :cli)

(exit (apply main (provider-command-line-args (command-line))))

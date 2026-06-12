;; -*- Gerbil -*-
(import :gerbil/gambit
        :cli)

(exit (apply main (cddr (command-line))))

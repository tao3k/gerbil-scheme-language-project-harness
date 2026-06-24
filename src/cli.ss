;;; -*- Gerbil -*-
;;; Package executable entrypoint for the Gerbil Scheme project harness.

(import (rename-in :cli-launcher
                   (main launcher-main)
                   (command-line-args launcher-command-line-args)
                   (provider-command-line-args launcher-provider-command-line-args)))

(export main
        command-line-args
        provider-command-line-args)

(def (main . args)
  (apply launcher-main args))

(def command-line-args launcher-command-line-args)
(def provider-command-line-args launcher-provider-command-line-args)

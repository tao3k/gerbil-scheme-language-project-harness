;;; -*- Gerbil -*-
(import :gerbil/gambit :std/misc/process)

(def (run-command! command)
  (let (status (run-process command check-status: #f))
    (exit status)))

(def (provider-cli-main args)
  (run-command! (append ["gxi" "bin/runner.ss"] args)))


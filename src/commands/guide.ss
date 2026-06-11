;;; -*- Gerbil -*-
;;; Agent guide command output.

(export print-guide)

(def (print-guide)
  (displayln "gerbil-scheme-harness guide")
  (displayln "|cmd prime=gerbil-scheme-harness search prime --view seeds .")
  (displayln "|cmd fzf=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")
  (displayln "|cmd owner=gerbil-scheme-harness search owner <path> --view seeds .")
  (displayln "|cmd owner-items=gerbil-scheme-harness search owner <path> items --query <symbol> --names-only .")
  (displayln "|cmd query-code=gerbil-scheme-harness query <path> --term <symbol> --workspace . --code")
  (displayln "|cmd check=gerbil-scheme-harness check --changed ."))

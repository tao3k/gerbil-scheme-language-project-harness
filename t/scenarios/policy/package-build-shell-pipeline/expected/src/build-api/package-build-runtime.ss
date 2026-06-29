;;; -*- Gerbil -*-
(import :std/misc/process)

(def (run-refresh!)
  (run-process ["gxc" "-static" "src/orders/core.ss"] check-status: #t))


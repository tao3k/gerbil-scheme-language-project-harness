;;; -*- Gerbil -*-
(def (refresh!)
  (invoke "sh" ["-c" "find src -name '*.ss' -print | xargs gxc -static"])
  #t)


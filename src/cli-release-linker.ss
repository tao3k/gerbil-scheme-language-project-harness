;;; -*- Gerbil -*-
;;; Release-only static linker root for the native gslph executable.

(import (rename-in :cli-launcher (main cli-main))
        (only-in :commands/agent agent-main)
        (only-in :commands/check check-main)
        (only-in :commands/evidence evidence-main)
        (only-in :commands/guide guide-main)
        (only-in :commands/info info-main)
        (only-in :commands/query query-main)
        (only-in :commands/search search-main))
(export main
        release-command-dispatch
        release-command-mains)

;;; Static release boundary:
;;; - The launcher keeps cold commands behind load-module.
;;; - This module exists only as the compile-exe root so the release binary
;;;   links the cold command modules into Gerbil's static module table.
;; : (List CommandMain)
(def release-command-dispatch
  [["search" search-main]
   ["query" query-main]
   ["check" check-main]
   ["evidence" evidence-main]
   ["agent" agent-main]
   ["guide" guide-main]
   ["info" info-main]])

;; : (List CommandMain)
(def release-command-mains
  [search-main
   query-main
   check-main
   evidence-main
   agent-main
   guide-main
   info-main])

(register-static-command-dispatch! release-command-dispatch)

;; : (-> Args Integer)
(def (main . args)
  (register-static-command-dispatch! release-command-dispatch)
  (apply cli-main args))

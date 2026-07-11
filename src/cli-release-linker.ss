;;; -*- Gerbil -*-
;;; Release-only static linker root for the native gslph executable.

(import (rename-in :gslph/src/cli-launcher (main cli-main))
        (only-in :gslph/src/commands/agent agent-main)
        (only-in :gslph/src/commands/evidence evidence-main)
        (only-in :gslph/src/commands/fmt fmt-main)
        (only-in :gslph/src/commands/guide guide-main)
        (only-in :gslph/src/commands/info info-main)
        (only-in :gslph/src/commands/query query-main)
        (only-in :gslph/src/commands/search search-main))
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
   ["evidence" evidence-main]
   ["fmt" fmt-main]
   ["agent" agent-main]
   ["guide" guide-main]
   ["info" info-main]])

;; : (List CommandMain)
(def release-command-mains
  [search-main
   query-main
   evidence-main
   fmt-main
   agent-main
   guide-main
   info-main])

(register-static-command-dispatch! release-command-dispatch)

;; : (-> Args Integer)
(def (main . args)
  (register-static-command-dispatch! release-command-dispatch)
  (exit (apply cli-main (executable-argv args))))

;; : (-> Args Args)
(def (executable-argv fallback)
  (let (argv (command-line))
    (if (pair? argv)
      (cdr argv)
      fallback)))

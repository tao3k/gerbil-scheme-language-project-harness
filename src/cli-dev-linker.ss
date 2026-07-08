;;; -*- Gerbil -*-
;;; Development executable root for gslph.

(import :gerbil/gambit
        (rename-in :cli-launcher (main launcher-main)))
(export main)

;;; Dev binary boundary:
;;; - Keep the executable root thin.  Command implementations are either native
;;;   fast paths inside `cli-launcher` or dynamically loaded after argv selects
;;;   the command.

;; : (-> Args Integer)
(def (main . args)
  (apply launcher-main args))

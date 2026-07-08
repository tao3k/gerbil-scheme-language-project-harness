;;; -*- Gerbil -*-
;;; Installed executable root for gslph.

(import :gerbil/gambit
        (rename-in :cli-launcher (main launcher-main)))
(export main)

;;; Install binary boundary:
;;; - The installed executable is the native command boundary.
;;; - Cold command implementations are dynamically loaded after argv selects
;;;   them; launcher load paths provide Gerbil stdlib and package modules.

;; : (-> Args Integer)
(def (main . args)
  (apply launcher-main args))

;;; -*- Gerbil -*-
;;; Installed executable root for gslph.

(import (rename-in :cli-launcher (main launcher-main))
        (only-in :commands/check check-main))
(export main
        install-command-dispatch
        install-command-mains)

;;; Install binary boundary:
;;; - Statically register the class-heavy check command so the installed
;;;   launcher does not load checker modules dynamically at runtime.
;;; - Other commands remain on launcher fast paths or the existing dynamic
;;;   boundary until they have a measured static-link need.
;; : (List CommandMain)
(def install-command-dispatch
  [["check" check-main]])

;; : (List CommandMain)
(def install-command-mains
  [check-main])

(register-static-command-dispatch! install-command-dispatch)

;; : (-> Args Integer)
(def (main . args)
  (apply launcher-main args))

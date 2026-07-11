;;; -*- Gerbil -*-
;;; Installed executable root for gslph.

(import :gerbil/gambit
        :std/misc/path)
(export main)

;;; Install binary boundary:
;;; - The installed executable is the native command boundary.
;;; - Cold command implementations are dynamically loaded after argv selects
;;;   them; launcher load paths provide Gerbil stdlib and package modules.

;; : (-> Args Integer)
(def (main . args)
  (add-load-path! (path-expand ".gerbil/lib" (current-directory)))
  (##global-var-set! (##make-global-var 'load-module) load-module)
  (load-module "gslph/src/cli-launcher")
  (let (launcher-main (eval 'gslph/src/cli-launcher#main))
    (unless (procedure? launcher-main)
      (error "provider-runtime-source-mismatch"
             "gslph/src/cli-launcher"
             'gslph/src/cli-launcher#main
             launcher-main))
    (exit (apply launcher-main (executable-argv args)))))

;; : (-> Args Args)
(def (executable-argv fallback)
  (let (argv (command-line))
    (if (pair? argv)
      (cdr argv)
      fallback)))

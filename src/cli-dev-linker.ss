;;; -*- Gerbil -*-
;;; Development executable root for gslph.

(import :gerbil/gambit
        :std/misc/path)
(export main)

;;; Dev binary boundary:
;;; - Keep the executable root thin.  Search owner-items has a launcher-native
;;;   fast path; broader command implementations remain dynamic.

;; : (-> Args Integer)
(def (main . args)
  (add-load-path! (path-expand ".gerbil/lib" (current-directory)))
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

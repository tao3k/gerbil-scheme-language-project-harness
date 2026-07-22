;;; -*- Gerbil -*-
;;; Installed executable root for gslph.

(import :gerbil/gambit
        (only-in :std/misc/path path-directory path-expand path-normalize))
(export main)

;;; Install binary boundary:
;;; - The installed executable is the native command boundary.
;;; - Cold command implementations are dynamically loaded after argv selects
;;;   them from the sibling library directory inside the CAS artifact.

;; : (-> Path)
(def (artifact-library-directory)
  (let (argv (command-line))
    (unless (pair? argv)
      (error "missing executable path"))
    (path-normalize
     (path-expand "../lib"
                  (path-directory
                   (path-expand (car argv) (current-directory)))))))

;; : (-> Args Integer)
(def (main . args)
  (add-load-path! (artifact-library-directory))
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

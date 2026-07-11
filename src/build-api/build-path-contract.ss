;;; -*- Gerbil -*-
;;; Minimal path contracts for build/install tests.

(import (only-in :std/misc/path path-directory path-expand path-normalize path-strip-directory)
        :gerbil/gambit)
(export clean-target
        configure-build-root!
        configure-build-path-root!
        dev-launcher-binpath
        install-launcher-binpath)

(def package-root #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root)))

;; : (-> Path Void)
;; Configure only the shared path contract for a native build owner.
(def (configure-build-path-root! root)
  (configure-build-root! root))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

;; : (-> Path)
(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

;; : (-> Path)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install asp gerbil-scheme into $HOME/.local/bin")))

;; : (-> Path Void)
(def (delete-file* path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> Path Void)
(def (cleanup-compile-exe-artifacts! binpath)
  (let* ((bindir (path-directory binpath))
         (name (path-strip-directory binpath))
         (prefix (string-append name "__exe")))
    (for-each
     (lambda (suffix)
       (delete-file* (path-expand (string-append prefix suffix) bindir)))
     '(".c" "_.c" ".scm" ".o" "_.o"))))

;; : (-> Void)
(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (delete-file* binpath)
    (cleanup-compile-exe-artifacts! binpath))
  #!void)

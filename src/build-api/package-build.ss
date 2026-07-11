;;; -*- Gerbil -*-
;;; Package-local Gerbil environment and build-lock support.

(import (only-in :std/misc/path path-directory path-expand path-normalize)
         (only-in :std/srfi/13 string-prefix?)
         (only-in :std/misc/process run-process)
         (only-in :gerbil/tools/env setup-local-pkg-env!)
        :gerbil/gambit)
(export gslph-package-configure-build-root!
         gslph-package-build-package-name
         gslph-package-build-active-gerbil-path
         gslph-package-build-active-gerbil-lib-path
         gslph-package-build-lock-path
         gslph-package-build-with-lock)

(def package-root #f)

;; : Real
(def +gslph-package-build-lock-sleep-seconds+ 0.05)

;; : Integer
(def +gslph-package-build-lock-owner-grace-seconds+ 1)

;; : Integer
(def +gslph-package-build-lock-report-seconds+ 5)

;; : (-> Path Path)
(def (package-local-gerbil-path root)
  (path-expand ".gerbil" root))

;; : (-> MaybeString Boolean)
(def (package-build-non-empty-string? value)
  (and (string? value)
       (> (string-length value) 0)))

;; : (-> Path (Maybe String))
(def (gslph-package-build-package-name root)
  (let* ((package-file (path-expand "gerbil.pkg" root))
         (plist (with-catch
                 (lambda (_) #f)
                 (lambda () (call-with-input-file package-file read)))))
    (let loop ((rest plist))
      (if (and (pair? rest) (pair? (cdr rest)))
        (if (eq? (car rest) 'package:)
          (let (name (cadr rest))
            (cond
             ((symbol? name) (symbol->string name))
             ((string? name) name)
             (else #f)))
          (loop (cdr rest)))
        #f))))

;; : (-> Path Path)
(def (gslph-package-build-active-gerbil-path root)
  (path-expand
   (let (path (getenv "GERBIL_PATH" #f))
     (if (package-build-non-empty-string? path)
       path
       (package-local-gerbil-path root)))))

;; : (-> Path Path)
(def (gslph-package-build-active-gerbil-lib-path root)
  (path-expand "lib" (gslph-package-build-active-gerbil-path root)))

;; : (-> Path Path)
(def (gslph-package-build-lock-path root)
  (path-expand "build/gslph-package.lock"
               (gslph-package-build-active-gerbil-path root)))

;; : (-> Path Path)
(def (gslph-package-build-lock-owner-path lock-path)
  (path-expand "owner.scm" lock-path))

;; : (-> Path Void)
(def (gslph-package-build-ensure-directory! path)
  (when (and path
             (not (string=? path ""))
             (not (string=? path "."))
             (not (file-exists? path)))
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent path)))
        (gslph-package-build-ensure-directory! parent)))
    (unless (file-exists? path)
      (create-directory path))))

;; : (-> Path Boolean)
(def (gslph-package-build-try-acquire-lock! lock-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (create-directory lock-path)
     #t)))

;; : (-> Path Void)
(def (gslph-package-build-write-lock-owner! lock-path)
  (call-with-output-file
   (gslph-package-build-lock-owner-path lock-path)
   (lambda (port)
     (write `(gslph-package-build-owner
              ,(##os-getpid)
              ,(current-jiffy))
            port)
     (newline port))))

;; : (-> Path (Maybe Datum))
(def (gslph-package-build-read-lock-owner lock-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (call-with-input-file
      (gslph-package-build-lock-owner-path lock-path)
      read))))

;; : (-> Datum (Maybe Integer))
(def (gslph-package-build-lock-owner-pid owner)
  (and (pair? owner)
       (eq? (car owner) 'gslph-package-build-owner)
       (pair? (cdr owner))
       (integer? (cadr owner))
       (cadr owner)))

;; : (-> Integer Boolean)
(def (gslph-package-build-process-live? pid)
  (and (integer? pid)
       (> pid 0)
       (with-catch
        (lambda (_) #f)
        (lambda ()
          (run-process
           ["/bin/kill" "-0" (number->string pid)]
           stderr-redirection: #t)
          #t))))

;; : (-> Path Boolean)
(def (gslph-package-build-reclaim-lock! lock-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (owner-path (gslph-package-build-lock-owner-path lock-path))
       (when (file-exists? owner-path)
         (delete-file owner-path))
       (delete-directory lock-path)
       #t))))

;; : (-> Symbol Path (Maybe Integer) Void)
(def (gslph-package-build-display-lock-state state lock-path owner-pid)
  (display "[gslph-package-lock] state=")
  (display state)
  (display " path=")
  (display lock-path)
  (when owner-pid
    (display " owner-pid=")
    (display owner-pid))
  (newline)
  (force-output))

;; : (-> Path Void)
(def (gslph-package-build-release-lock! lock-path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (gslph-package-build-reclaim-lock! lock-path))))

;; : (-> Path Void)
(def (gslph-package-build-acquire-lock! lock-path)
  (let loop ((missing-owner-since #f)
             (last-report-jiffy #f))
    (if (gslph-package-build-try-acquire-lock! lock-path)
      (gslph-package-build-write-lock-owner! lock-path)
      (let* ((now-jiffy (current-jiffy))
             (owner (gslph-package-build-read-lock-owner lock-path))
             (owner-pid (gslph-package-build-lock-owner-pid owner))
             (owner-live? (and owner-pid
                               (gslph-package-build-process-live? owner-pid)))
             (owner-grace-expired?
              (and (not owner-pid)
                   missing-owner-since
                   (>= (- now-jiffy missing-owner-since)
                       (* +gslph-package-build-lock-owner-grace-seconds+
                          (jiffies-per-second)))))
             (report-due?
              (or (not last-report-jiffy)
                  (>= (- now-jiffy last-report-jiffy)
                      (* +gslph-package-build-lock-report-seconds+
                         (jiffies-per-second))))))
        (cond
         ((and owner-pid (not owner-live?))
          (when (gslph-package-build-reclaim-lock! lock-path)
            (gslph-package-build-display-lock-state 'reclaimed lock-path owner-pid))
          (loop #f now-jiffy))
         (owner-grace-expired?
          (when (gslph-package-build-reclaim-lock! lock-path)
            (gslph-package-build-display-lock-state 'reclaimed lock-path #f))
          (loop #f now-jiffy))
         (else
          (when report-due?
            (gslph-package-build-display-lock-state 'waiting lock-path owner-pid))
          (thread-sleep! +gslph-package-build-lock-sleep-seconds+)
          (loop (if owner-pid #f (or missing-owner-since now-jiffy))
                (if report-due? now-jiffy last-report-jiffy))))))))

;; : (-> Procedure Datum)
(def (gslph-package-build-with-lock thunk)
  (ensure-package-build-root!)
  (let (lock-path (gslph-package-build-lock-path package-root))
    (gslph-package-build-ensure-directory! (path-directory lock-path))
    (gslph-package-build-acquire-lock! lock-path)
    (dynamic-wind
      void
      thunk
      (lambda ()
        (gslph-package-build-release-lock! lock-path)))))

;; : (-> Path Void)
(def (gslph-package-configure-build-root! root)
  (let (active-gerbil-path (gslph-package-build-active-gerbil-path root))
    (set! package-root (path-normalize root))
    (current-directory package-root)
     (setup-local-pkg-env! #t)
     (setenv "GERBIL_PATH" active-gerbil-path)
     (add-load-path! (path-expand "lib" active-gerbil-path))))

;; : (-> Void)
(def (ensure-package-build-root!)
  (unless package-root
    (gslph-package-configure-build-root! (current-directory))))

;; : (-> Path MaybeString)

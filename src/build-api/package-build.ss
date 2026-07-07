;;; -*- Gerbil -*-
;;; Lightweight package API compiler for downstream dependency installs.

(import (only-in :std/make make)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar with-catch)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        (only-in "./package-spec"
                 gslph-package-api-spec
                 gslph-package-api-stage-specs)
        (only-in "./worker-count" sync-build-worker-count!)
        :gerbil/gambit)
(export gslph-package-configure-build-root!
        gslph-package-build-active-gerbil-path
        gslph-package-build-active-gerbil-lib-path
        gslph-package-build-lock-path
        gslph-package-build-with-lock
        gslph-package-compile-root-modules-target
        gslph-package-compile-gxtest-target
        gslph-package-compile-target)

(def package-root #f)
(def source-root #f)
(def test-root #f)
(def package-name #f)

;; : Integer
(def +gslph-package-build-lock-timeout-seconds+ 600)

;; : Real
(def +gslph-package-build-lock-sleep-seconds+ 0.05)

;; : (-> Path Path)
(def (package-local-gerbil-path root)
  (path-expand ".gerbil" root))

;; : (-> MaybeString Boolean)
(def (package-build-non-empty-string? value)
  (and (string? value)
       (> (string-length value) 0)))

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
(def (gslph-package-build-release-lock! lock-path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? lock-path)
       (delete-directory lock-path)))))

;; : (-> Integer Integer Boolean)
(def (gslph-package-build-lock-timeout? start-jiffy now-jiffy)
  (> (- now-jiffy start-jiffy)
     (* +gslph-package-build-lock-timeout-seconds+
        (jiffies-per-second))))

;; : (-> Path Integer Void)
(def (gslph-package-build-acquire-lock! lock-path start-jiffy)
  (unless (gslph-package-build-try-acquire-lock! lock-path)
    (if (gslph-package-build-lock-timeout? start-jiffy (current-jiffy))
      (error "timed out waiting for gslph package build lock" lock-path)
      (begin
        (thread-sleep! +gslph-package-build-lock-sleep-seconds+)
        (gslph-package-build-acquire-lock! lock-path start-jiffy)))))

;; : (-> Procedure Datum)
(def (gslph-package-build-with-lock thunk)
  (ensure-package-build-root!)
  (let (lock-path (gslph-package-build-lock-path package-root))
    (gslph-package-build-ensure-directory! (path-directory lock-path))
    (gslph-package-build-acquire-lock! lock-path (current-jiffy))
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
    (add-load-path! (path-expand "lib" active-gerbil-path)))
  (set! source-root (path-expand "src" package-root))
  (set! test-root (path-expand "t" package-root))
  (set! package-name (read-build-package-name package-root)))

;; : (-> Void)
(def (ensure-package-build-root!)
  (unless package-root
    (gslph-package-configure-build-root! (current-directory))))

;; : (-> Path MaybeString)
(def (read-build-package-name root)
  (let* ((package-file (path-expand "gerbil.pkg" root))
         (plist (with-catch
                 (lambda (_) #f)
                 (lambda () (call-with-input-file package-file read))))
         (name (and plist (plist-ref plist 'package: #f))))
    (cond
     ((symbol? name) (symbol->string name))
     ((string? name) name)
     (else #f))))

;; : (-> List Symbol Datum Datum)
(def (plist-ref plist key default)
  (let lp ((rest plist))
    (if (and (pair? rest) (pair? (cdr rest)))
      (if (eq? (car rest) key)
        (cadr rest)
        (lp (cddr rest)))
      default)))

;; : (-> String)
(def (source-output-prefix)
  (ensure-package-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  (string-append package-name "/src"))

;; : (-> String)
(def (package-root-output-prefix)
  (ensure-package-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  package-name)

;; : (-> String)
(def (test-output-prefix)
  (ensure-package-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  (string-append package-name "/t"))

(def (gslph-package-build-elapsed-micros start-jiffy end-jiffy)
  (inexact->exact
   (round
    (* 1000000
       (/ (- end-jiffy start-jiffy)
          (jiffies-per-second))))))

(def (gslph-package-build-debug-tracking-line receipt)
  (display "|gslph-compile-debug ")
  (write receipt)
  (newline)
  (force-output))

(def (gslph-package-compile-stage/owner phase modules worker-count optimized release
                                      prefix srcdir debug?)
  (unless (null? modules)
    (let (started-at (current-jiffy))
      (make modules
        optimize: optimized
        build-release: release
        build-optimized: optimized
        parallelize: worker-count
        prefix: prefix
        srcdir: srcdir)
      (when debug?
        (gslph-package-build-debug-tracking-line
         `((phase . ,phase)
           (status . compiled)
           (command . "std/make")
           (command-dir . ,(current-directory))
           (modules . ,modules)
           (module-count . ,(length modules))
           (worker-count . ,worker-count)
           (optimized . ,optimized)
           (release . ,release)
           (prefix . ,prefix)
           (srcdir . ,srcdir)
           (elapsed-micros . ,(gslph-package-build-elapsed-micros
                               started-at
                               (current-jiffy)))))))))

;; : (-> Void)
(def (gslph-package-compile-stage modules worker-count optimized release . maybe-debug)
  (gslph-package-compile-stage/owner
   'compile-api-stage
   modules
   worker-count
   optimized
   release
   (source-output-prefix)
   source-root
   (and (pair? maybe-debug) (car maybe-debug))))

;; : (-> Path ModulePath)
(def (gxtest-test-module-path path)
  (if (string-prefix? "t/" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path ModulePath)
(def (gxtest-source-module-path path)
  (if (string-prefix? "src/" path)
    (substring path 4 (string-length path))
    path))

;; : (-> Boolean Boolean Boolean Boolean Boolean Void)
(def (gslph-package-compile-target verbose debug no-optimize optimized release)
  (ensure-package-build-root!)
  (current-directory package-root)
  (gslph-package-build-with-lock
   (lambda ()
     (let ((worker-count (sync-build-worker-count!))
           (optimize? (and optimized (not no-optimize))))
      (for-each
       (lambda (stage)
          (gslph-package-compile-stage stage worker-count optimize? release debug))
       (gslph-package-api-stage-specs)))))
  #!void)

;; : (-> (List BuildSpec) Void)
(def (gslph-package-compile-root-modules-target modules)
  (ensure-package-build-root!)
  (current-directory package-root)
  (gslph-package-build-with-lock
   (lambda ()
     (make modules
       optimize: #f
       parallelize: 1
       prefix: (package-root-output-prefix)
       srcdir: package-root)))
  #!void)

;; : (-> (List ModulePath) (List Path) Integer [Boolean] Void)
(def (gslph-package-compile-gxtest-target source-modules files worker-count . maybe-debug)
  (ensure-package-build-root!)
  (current-directory package-root)
  (gslph-package-build-with-lock
   (lambda ()
     (let (debug? (and (pair? maybe-debug) (car maybe-debug)))
       (gslph-package-compile-stage/owner
        'compile-selected-source-gxtest
        (map gxtest-source-module-path source-modules)
        worker-count
        #f
        #f
        (source-output-prefix)
        source-root
        debug?)
       (gslph-package-compile-stage/owner
        'compile-selected-test-gxtest
        (map gxtest-test-module-path files)
        worker-count
        #f
        #f
        (test-output-prefix)
        test-root
        debug?))))
  #!void)

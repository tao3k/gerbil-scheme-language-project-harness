;;; -*- Gerbil -*-
;;; Lightweight package API compiler for downstream dependency installs.

(import (only-in :std/make make)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar with-catch)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        (only-in "./package-spec" gslph-package-api-spec)
        (only-in "./worker-count" sync-build-worker-count!)
        :gerbil/gambit)
(export gslph-package-configure-build-root!
        gslph-package-compile-root-modules-target
        gslph-package-compile-gxtest-target
        gslph-package-compile-target)

(def package-root #f)
(def source-root #f)
(def test-root #f)
(def package-name #f)

;; : (-> Path Void)
(def (gslph-package-configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setup-local-pkg-env! #t)
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
  (make (gslph-package-api-spec)
    verbose: (and verbose 9)
    debug: (and debug 'env)
    optimize: (and optimized (not no-optimize))
    build-release: release
    build-optimized: optimized
    parallelize: (sync-build-worker-count!)
    prefix: (source-output-prefix)
    srcdir: source-root)
  #!void)

;; : (-> (List BuildSpec) Void)
(def (gslph-package-compile-root-modules-target modules)
  (ensure-package-build-root!)
  (current-directory package-root)
  (make modules
    optimize: #f
    parallelize: 1
    prefix: (package-root-output-prefix)
    srcdir: package-root)
  #!void)

;; : (-> (List ModulePath) (List Path) Integer Void)
(def (gslph-package-compile-gxtest-target source-modules files worker-count)
  (ensure-package-build-root!)
  (current-directory package-root)
  (unless (null? source-modules)
    (make (map gxtest-source-module-path source-modules)
      optimize: #f
      parallelize: worker-count
      prefix: (source-output-prefix)
      srcdir: source-root))
  (make (map gxtest-test-module-path files)
    optimize: #f
    parallelize: worker-count
    prefix: (test-output-prefix)
    srcdir: test-root)
  #!void)

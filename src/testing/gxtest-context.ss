;;; -*- Gerbil -*-
;;; Shared gxtest build-root context and module path helpers.

(import (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        :gerbil/gambit)

(export package-root
        source-root
        test-root
        package-name
        configure-build-root!
        ensure-build-root!
        read-build-package-name
        package-output-prefix
        source-output-prefix
        test-output-prefix
        module-path-stem
        gxtest-test-module-path
        gxtest-source-module-path
        gxtest-file-module-symbol
        gxtest-normalize-module-path)

(def package-root #f)
(def source-root #f)
(def test-root #f)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
  (setup-local-pkg-env! #t)
  (set! source-root (path-expand "src" package-root))
  (set! test-root (path-expand "t" package-root))
  (set! package-name (read-build-package-name package-root)))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

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

;; plist-ref
;;   : (-> PropertyList Symbol Datum Datum)
;;   | doc m%
;;       `plist-ref` is the local property-list selector used while reading
;;       `gerbil.pkg`; it returns `default` when the key is absent or the list
;;       shape is incomplete.
;;     %
(def (plist-ref plist key default)
  (match plist
    ([head value . rest]
     (if (eq? head key)
       value
       (plist-ref rest key default)))
    (else default)))

;; : (-> String String)
(def (package-output-prefix root-name)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  (string-append package-name "/" root-name))

;; : (-> String)
(def (source-output-prefix)
  (package-output-prefix "src"))

;; : (-> String)
(def (test-output-prefix)
  (package-output-prefix "t"))

;; : (-> String)
(def (module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

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

;; : (-> Path Path)
(def (gxtest-trim-leading-dot-slash path)
  (if (string-prefix? "./" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path Symbol)
(def (gxtest-file-module-symbol file)
  (ensure-build-root!)
  (string->symbol
   (string-append ":"
                  package-name
                  "/"
                  (module-path-stem
                   (gxtest-trim-leading-dot-slash file)))))

;; : (-> ModulePath ModulePath)
(def (gxtest-normalize-module-path module-path)
  (if (and package-name
           (string-prefix? (string-append package-name "/") module-path))
    (substring module-path
               (+ (string-length package-name) 1)
               (string-length module-path))
    module-path))

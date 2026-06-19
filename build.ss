#!/usr/bin/env gxi
;; -*- Gerbil -*-
(import :std/make
        :clan/base
        :clan/building
        (only-in :std/misc/path directory-files)
        :std/misc/ports
        :std/misc/process
        (only-in :std/os/pid getpid)
        (only-in :std/os/signal kill)
        (only-in :std/sort sort)
        :std/srfi/13
        (only-in :std/srfi/1 filter find))

(include "build-support/provider-cli.ss")

(def (build-prefix)
  (getenv "GERBIL_BUILD_PREFIX" (path-expand ".build/gerbil" (current-directory))))

(def (gerbil-bin name)
  (let ((usr-local-bin (string-append "/usr/local/bin/" name))
        (homebrew-bin (string-append "/opt/homebrew/bin/" name))
        (default-bin (path-expand (string-append "bin/" name) (gerbil-home)))
        (sibling-bin (path-expand (string-append "../bin/" name) (gerbil-home))))
    (cond
     ((file-exists? default-bin) default-bin)
     ((file-exists? sibling-bin) sibling-bin)
     ((file-exists? usr-local-bin) usr-local-bin)
     ((file-exists? homebrew-bin) homebrew-bin)
     (else name))))

(def (ensure-gerbil-gsc!)
  (let (gsc (gerbil-bin "gsc"))
    (when (file-exists? gsc)
      (setenv "GERBIL_WRAPPER_REAL_GSC" gsc)
      (setenv "GERBIL_WRAPPER_RUNTIME_ARG"
              (string-append "-:~~=" (path-normalize (gerbil-home))))
      (setenv "GERBIL_GSC"
             (compile-build-support-executable!
              "gsc-gerbil-build"
               "build-support/gsc-wrapper-runtime.ss"
               ["build-support/gsc-wrapper-runtime.ss"
                "build-support/provider-cli.ss"])))))

;;; Boundary:
;;; - clan/building owns build source discovery and the build load path.
;;; - Provider modules stay under src/; selected t/unit helpers are compiled
;;;   because tests import them as reusable modules.
;; : (List String)
(def +provider-test-helper-modules+
  ["t/unit/evidence-graph"
   "t/unit/policy/poo-scenarios"
   "t/unit/poo/runtime-witness"
   "t/unit/schema/bundle"
   "t/unit/schema/conformance"
   "t/unit/search/owner-items"
   "t/unit/search/prime-packet"
   "t/unit/search/structural-index"
   "t/unit/snapshot/parser"])

;; : (-> String Boolean)
(def (provider-build-module? module)
  (string-prefix? "src/" module))

;; : (-> (List String))
(def (spec)
  (!> (all-gerbil-modules)
      (cut filter provider-build-module? <>)
      (cut append <> +provider-test-helper-modules+)))

(init-build-environment!
 name: "gerbil-scheme-language-project-harness"
 deps: '("clan" "gerbil-poo")
 spec: spec)

;; : (-> Datum Symbol MaybeDatum )
(def (datum-field-value datum field)
  (let (items (and (list? datum) (memq field datum)))
    (and items
         (pair? (cdr items))
         (cadr items))))

(def (compile-command? args)
  (or (member "compile" args)
      (member "full" args)
      (member "native" args)
      (member "native-link" args)
      (member "native-diagnose" args)))

;;; Boundary:
;;; - Package dependency preparation is owned by gerbil.pkg/gxpkg.
;;; - Test runs import POO-backed guide modules, so they need the same package store as compile runs.
;; : (-> (List String) Boolean )
(def (package-dependency-command? args)
  (or (compile-command? args)
      (member "test" args)))

(def (native-command? args)
  (or (member "native" args)
      (member "native-link" args)
      (member "native-full" args)
      (member "native-full-link" args)))

(def (full-command? args)
  (or (member "full" args)
      (member "native-full" args)))

(def (provider-build-lock-dir)
  (path-expand "provider-build.lock" (build-prefix)))

(def (provider-build-lock-owner-path lock-dir)
  (path-expand "owner" lock-dir))

(def (write-provider-build-lock-owner! lock-dir)
  (call-with-output-file (provider-build-lock-owner-path lock-dir)
    (lambda (port)
      (write `(provider-build-lock
               pid: ,(getpid)
               cwd: ,(current-directory))
             port)
      (newline port))))

(def (read-provider-build-lock-owner lock-dir)
  (let (owner-path (provider-build-lock-owner-path lock-dir))
    (and (file-exists? owner-path)
         (with-catch
          (lambda (_) #f)
          (lambda ()
            (call-with-input-file owner-path read))))))

(def (provider-build-lock-owner-pid lock-dir)
  (let (pid (datum-field-value
             (read-provider-build-lock-owner lock-dir)
             'pid:))
    (and (integer? pid) pid)))

(def (provider-build-lock-pid-alive? pid)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (kill pid 0)
     #t)))

(def (try-acquire-provider-build-lock! lock-dir)
  (if (zero?
       (run-process ["mkdir" lock-dir]
                    stdin-redirection: #f
                    stdout-redirection: #f
                    stderr-redirection: #t
                    coprocess: process-status
                    check-status: #f))
    (begin
      (write-provider-build-lock-owner! lock-dir)
      #t)
    #f))

(def (empty-provider-build-lock? lock-dir)
  (and (file-exists? lock-dir)
       (null? (directory-files lock-dir))))

(def (remove-empty-provider-build-lock! lock-dir)
  (if (empty-provider-build-lock? lock-dir)
    (begin
      (display "... remove stale empty provider build lock ")
      (display lock-dir)
      (newline)
      (zero?
       (run-process ["rmdir" lock-dir]
                    stdin-redirection: #f
                    stdout-redirection: #f
                    stderr-redirection: #t
                    coprocess: process-status
                    check-status: #f)))
    #f))

(def (remove-dead-provider-build-lock! lock-dir)
  (let (pid (provider-build-lock-owner-pid lock-dir))
    (if (and pid (not (provider-build-lock-pid-alive? pid)))
      (begin
        (display "... remove stale provider build lock for dead pid ")
        (display pid)
        (display " ")
        (display lock-dir)
        (newline)
        (let (owner-path (provider-build-lock-owner-path lock-dir))
          (when (file-exists? owner-path)
            (delete-file owner-path)))
        (zero?
         (run-process ["rmdir" lock-dir]
                      stdin-redirection: #f
                      stdout-redirection: #f
                      stderr-redirection: #t
                      coprocess: process-status
                      check-status: #f)))
      #f)))

(def (display-provider-build-lock-wait lock-dir remaining)
  (when (zero? (modulo remaining 10))
    (display "... waiting for provider build lock ")
    (display lock-dir)
    (display " remaining=")
    (display remaining)
    (newline)))

(def (acquire-provider-build-lock! lock-dir)
  (create-directory* (path-directory lock-dir))
  (let loop ((remaining 180) (empty-lock-seen? #f))
    (cond
     ((try-acquire-provider-build-lock! lock-dir)
      lock-dir)
     ((and empty-lock-seen?
           (remove-empty-provider-build-lock! lock-dir))
      (loop remaining #f))
     ((remove-dead-provider-build-lock! lock-dir)
      (loop remaining #f))
     ((zero? remaining)
      (error "provider build lock is busy; stop the active build or remove the stale lock" lock-dir))
     (else
      (display-provider-build-lock-wait lock-dir remaining)
      (thread-sleep! 1)
      (loop (- remaining 1) (empty-provider-build-lock? lock-dir))))))

(def (release-provider-build-lock! lock-dir)
  (when (file-exists? lock-dir)
    (let (owner-path (provider-build-lock-owner-path lock-dir))
      (when (file-exists? owner-path)
        (delete-file owner-path)))
    (run-process ["rmdir" lock-dir]
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #t
                 coprocess: process-status
                 check-status: #f)))

(def (with-provider-build-lock! thunk)
  (let (lock-dir (provider-build-lock-dir))
    (acquire-provider-build-lock! lock-dir)
    (with-catch
     (lambda (exn)
       (release-provider-build-lock! lock-dir)
       (raise exn))
     (lambda ()
       (let (result (thunk))
         (release-provider-build-lock! lock-dir)
         result)))))

(def (gerbil-poo-installed-at? root)
  (and root
       (file-exists?
        (path-expand "lib/clan/poo/object.ssi" root))))

(def (home-gerbil-root)
  (let (home (getenv "HOME" #f))
    (and home (path-expand ".gerbil" home))))

(def (local-gerbil-poo-installed?)
  (gerbil-poo-installed-at?
   (path-expand ".gerbil" (current-directory))))

(def (home-gerbil-poo-installed?)
  (gerbil-poo-installed-at? (home-gerbil-root)))

(def (ensure-package-dependencies!)
  (unless (local-gerbil-poo-installed?)
    (if (home-gerbil-poo-installed?)
      (display "... install package dependencies into provider .gerbil (global gerbil-poo detected)\n")
      (display "... install package dependencies into provider .gerbil\n"))
    (invoke "gxpkg" ["deps" "-i"])))

(def (clean-compiled-provider-artifacts!)
  (let* ((lib-root (path-expand ".gerbil/lib" (current-directory)))
         (static-root (path-expand "static" lib-root))
         (package-root
          (path-expand "gerbil-scheme-language-project-harness" lib-root)))
    (display "... clean stale compiled provider artifacts\n")
    (invoke "rm" ["-rf" package-root])
    (when (file-exists? static-root)
      (invoke "find"
              [static-root
               "-name"
               "gerbil-scheme-language-project-harness__*"
               "-delete"]))))

(include "build-support/provider-build.ss")

(def (main . args)
  (ensure-gerbil-gsc!)
  (if (package-dependency-command? args)
    (with-provider-build-lock!
     (lambda ()
       (ensure-package-dependencies!)
       (when (and (compile-command? args)
                  (full-command? args))
         (clean-compiled-provider-artifacts!))
       (run-build! args)))
    (run-build! args)))

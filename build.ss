#!/usr/bin/env gxi
;; -*- Gerbil -*-
(import :std/make
        (only-in :std/iter for/fold)
        :std/misc/ports
        :std/misc/process
        (only-in :std/sort sort)
        :std/srfi/13
        :clan/base
        :clan/building)

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
               "build-support/gsc-wrapper-runtime.ss")))))

(def (ensure-source-load-path!)
  (add-load-path! (path-expand "src" (current-directory))))

(def (compile-command? args)
  (or (member "compile" args)
      (member "full" args)
      (member "native" args)
      (member "native-link" args)
      (member "native-diagnose" args)))

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

(def (try-acquire-provider-build-lock! lock-dir)
  (zero?
   (run-process ["mkdir" lock-dir]
                stdin-redirection: #f
                stdout-redirection: #f
                stderr-redirection: #t
                coprocess: process-status
                check-status: #f)))

(def (acquire-provider-build-lock! lock-dir)
  (create-directory* (path-directory lock-dir))
  (let loop ((remaining 180))
    (cond
     ((try-acquire-provider-build-lock! lock-dir)
      lock-dir)
     ((zero? remaining)
      (error "provider build lock is busy" lock-dir))
     (else
      (thread-sleep! 1)
      (loop (- remaining 1))))))

(def (release-provider-build-lock! lock-dir)
  (when (file-exists? lock-dir)
    (run-process ["rmdir" lock-dir]
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #t
                 coprocess: process-status
                 check-status: #f)))

(def (with-provider-build-lock! thunk)
  (let (lock-dir (provider-build-lock-dir))
    (acquire-provider-build-lock! lock-dir)
    (try
     (thunk)
     (finally
      (release-provider-build-lock! lock-dir)))))

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
               "gerbil-scheme-language-project-harness__*.scm"
               "-delete"]))))

(def (static-provider-artifacts-present?)
  (file-exists?
   (path-expand
    ".gerbil/lib/static/gerbil-scheme-language-project-harness__src__cli.scm"
    (current-directory))))

(def (provider-bin-dir)
  (let ((override (getenv "ASP_PROVIDER_BIN_DIR" #f))
        (monorepo-root (path-expand "../.." (current-directory))))
    (cond
     ((and override (not (equal? override "")))
      (path-expand override (current-directory)))
     ((file-exists? (path-expand "asp.toml" monorepo-root))
      (path-expand ".bin" monorepo-root))
     (else (path-expand ".bin" (current-directory))))))

(def (compile-build-support-executable! name source)
  (let* ((binary (path-expand name (path-expand "bin" (build-prefix))))
         (tmp-binary (string-append binary ".native-tmp"))
         (tmp-exe-stub (string-append tmp-binary "__exe.scm")))
    (if (native-binary-current? binary source)
      (begin
        (display "... build-support executable current ")
        (display binary)
        (newline))
      (begin
        (display "... compile build-support executable ")
        (display binary)
        (newline)
        (create-directory* (path-directory binary))
        (set-provider-compile-env!)
        (invoke "rm" ["-f" tmp-binary tmp-exe-stub])
        (invoke "gxc" ["-exe" "-o" tmp-binary source])
        (invoke "mv" [tmp-binary binary])
        (when (file-exists? tmp-exe-stub)
          (invoke "rm" ["-f" tmp-exe-stub]))
        (invoke "chmod" ["+x" binary])))
    binary))

(def (compile-full-native-cli!)
  (let* ((binary (path-expand "gerbil-scheme-harness"
                              (provider-bin-dir)))
         (tmp-binary (string-append binary ".native-tmp"))
         (exe-stub (string-append tmp-binary "__exe.scm")))
    (display "... compile native ")
    (display binary)
    (newline)
    (create-directory* (path-directory binary))
    (set-provider-compile-env!)
    (invoke "rm" ["-f" tmp-binary exe-stub])
    (invoke (compile-build-support-executable!
             "gerbil-native-link"
             "build-support/native-wrapper-runtime.ss")
            [tmp-binary binary])
    (when (file-exists? exe-stub)
      (invoke "rm" ["-f" exe-stub]))
    (invoke "chmod" ["+x" binary])
    binary))

(def (compile-native-fast-binary! name source)
  (let* ((binary (path-expand name (provider-bin-dir)))
         (tmp-binary (string-append binary ".native-tmp"))
         (tmp-exe-stub (string-append tmp-binary "__exe.scm")))
    (if (native-binary-current? binary source)
      (begin
        (display "... native fast current ")
        (display binary)
        (newline))
      (begin
        (display "... compile native fast ")
        (display binary)
        (newline)
        (create-directory* (path-directory binary))
        (set-provider-compile-env!)
        (invoke "rm" ["-f" tmp-binary tmp-exe-stub])
        (invoke "gxc" ["-exe" "-o" tmp-binary source])
        (invoke "mv" [tmp-binary binary])
        (when (file-exists? tmp-exe-stub)
          (invoke "rm" ["-f" tmp-exe-stub]))
        (invoke "chmod" ["+x" binary])))
    binary))

(def (compile-native-owner-items-binary!)
  (let* ((binary (path-expand "gerbil-scheme-search-owner-items"
                              (provider-bin-dir)))
         (source "build-support/owner-items-native.c")
         (tmp-binary (string-append binary ".native-tmp")))
    (if (file-current-for-source? binary source)
      (begin
        (display "... native owner-items current ")
        (display binary)
        (newline))
      (begin
        (display "... compile native owner-items ")
        (display binary)
        (newline)
        (create-directory* (path-directory binary))
        (invoke "rm" ["-f" tmp-binary])
        (invoke "cc" ["-O2" "-o" tmp-binary source])
        (invoke "mv" [tmp-binary binary])
        (invoke "chmod" ["+x" binary])))
    binary))

(def +native-fast-static-sources+
  ["src/support/list.ss"
   "src/parser/model.ss"
   "src/parser/support.ss"
   "src/parser/formals.ss"
   "src/parser/imports.ss"
   "src/parser/exports.ss"
   "src/parser/selectors.ss"
   "src/parser/syntax.ss"
   "src/parser/owner-items.ss"
   "src/support/args.ss"
   "src/commands/search-owner-items.ss"
   "src/commands/guide-sections.ss"])

(def (refresh-native-fast-static-artifacts!)
  (display "... refresh native fast static artifacts\n")
  (set-provider-compile-env!)
  (for-each compile-static-provider-source!
            +native-fast-static-sources+))

(def (script-executable? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (call-with-input-file path
       (lambda (in)
         (let ((first (read-char in))
               (second (read-char in)))
           (and (char? first)
                (char? second)
                (char=? first #\#)
                (char=? second #\!))))))))

(def (assert-native-provider-executable! binary)
  (when (script-executable? binary)
    (error "provider executable must be native, not a script" binary)))

(def (compile-native-provider-dispatcher!)
  (let* ((binary (path-expand "gerbil-scheme-harness"
                              (provider-bin-dir)))
         (tmp-binary (string-append binary ".native-tmp"))
         (harness-root (path-normalize (current-directory)))
         (config (provider-cli-config binary harness-root))
         (dispatcher-source
          (path-expand "provider-cli-dispatcher.c" (build-prefix))))
    (display "... compile native provider dispatcher ")
    (display binary)
    (newline)
    (create-directory* (path-directory binary))
    (set-provider-compile-env!)
    (write-provider-cli-config! binary harness-root)
    (write-provider-native-dispatcher-source! dispatcher-source config)
    (invoke "rm" ["-f" tmp-binary])
    (invoke "cc" ["-O2" "-DOWNER_ITEMS_NATIVE_NO_MAIN"
                  "-o" tmp-binary
                  dispatcher-source
                  "build-support/owner-items-native.c"])
    (invoke "mv" [tmp-binary binary])
    (invoke "chmod" ["+x" binary])
    (assert-native-provider-executable! binary)
    binary))

(def (compile-native-fast-cli!)
  (refresh-native-fast-static-artifacts!)
  (compile-native-fast-binary!
   "gerbil-scheme-search-extension"
   "src/search-fast/gerbil-scheme-search-extension.ss")
  (compile-native-fast-binary!
   "gerbil-scheme-search-pattern"
   "src/search-fast/gerbil-scheme-search-pattern.ss")
  (compile-native-owner-items-binary!)
  (compile-native-provider-dispatcher!))

(def (run-native-diagnose!)
  (let* ((diagnose-dir (path-expand "native-diagnose" (build-prefix)))
         (tmp-binary (path-expand "gerbil-scheme-harness.native-diagnose"
                                  diagnose-dir)))
    (display "... diagnose native ")
    (display tmp-binary)
    (newline)
    (create-directory* diagnose-dir)
    (set-provider-compile-env!)
    (unless (static-provider-artifacts-present?)
      (error "native diagnose requires static provider artifacts; run `gxi build.ss full` or `gxi build.ss native` first"))
    (invoke (compile-build-support-executable!
             "gerbil-native-diagnose"
             "build-support/native-wrapper-runtime.ss")
            [tmp-binary])
    tmp-binary))

(def (provider-build-module? module)
  (string-prefix? "src/" module))

(def (provider-build-spec)
  (!> (all-gerbil-modules)
      (cut filter provider-build-module? <>)))

(def (build-keys)
  [libdir: (path-expand "lib" (build-prefix))
   bindir: (path-expand "bin" (build-prefix))
   debug: #f])

(def (parse-build-options args)
  (let lp ((rest args)
           (options '()))
    (cond
     ((null? rest) options)
     ((equal? (car rest) "--release")
      (lp (cdr rest) (cons 'build-release: (cons #t options))))
     ((equal? (car rest) "--optimized")
      (lp (cdr rest) (cons 'build-optimized: (cons #t options))))
     ((equal? (car rest) "--debug")
      (lp (cdr rest) (cons 'debug: (cons #t options))))
     (else (error "Unexpected " rest)))))

(def (make-provider! options)
  (apply make
         (provider-build-spec)
         srcdir: (current-directory)
         (append options (build-keys))))

(def (clean-provider!)
  (apply make-clean
         (provider-build-spec)
         srcdir: (current-directory)
         (build-keys)))

(def (set-provider-compile-env!)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" (current-directory)))
  (setenv "GERBIL_LOADPATH" (path-expand "src" (current-directory))))

(def (build-source-directory? path)
  (eq? (file-type path) 'directory))

(def (static-provider-source-file? path)
  (equal? (path-extension path) ".ss"))

(def (static-provider-source-files)
  (def (walk dir acc)
    (for/fold (result acc) (entry (sort (directory-files dir) string<?))
      (if (member entry '("." ".."))
        result
        (let (path (path-expand entry dir))
          (cond
           ((build-source-directory? path)
            (walk path result))
           ((static-provider-source-file? path)
            (cons path result))
           (else result))))))
  (reverse (walk "src" '())))

(def (file-mtime-seconds path)
  (and (file-exists? path)
       (time->seconds (file-info-last-modification-time (file-info path)))))

(def (file-current-for-source? target source)
  (let ((target-time (file-mtime-seconds target))
        (source-time (file-mtime-seconds source)))
    (and target-time
         source-time
         (>= target-time source-time))))

(def (native-binary-current? binary source)
  (and (file-current-for-source? binary source)
       (not (script-executable? binary))))

(def (static-artifact-path source)
  (path-expand
   (string-append "static/gerbil-scheme-language-project-harness__"
                  (source-path-artifact-key (drop-source-extension source))
                  ".scm")
   (path-expand ".gerbil/lib" (current-directory))))

(def (drop-source-extension source)
  (if (string-suffix? ".ss" source)
    (substring source 0 (- (string-length source) 3))
    source))

(def (source-path-artifact-key source)
  (call-with-output-string ""
    (lambda (out)
      (for-each
       (lambda (char)
         (if (char=? char #\/)
           (write-string "__" out)
           (write-char char out)))
       (string->list source)))))

(def (compile-static-provider-source! source)
  (let (artifact (static-artifact-path source))
    (if (file-current-for-source? artifact source)
      (begin
        (display "... static current ")
        (display source)
        (newline))
      (invoke "gxc" ["-static" "-d" ".gerbil/lib" source]))))

(def (refresh-static-provider-artifacts!)
  (display "... refresh static provider artifacts\n")
  (set-provider-compile-env!)
  (for-each compile-static-provider-source!
            (static-provider-source-files)))

(def (run-build! args)
  (cond
   ((null? args) (make-provider! '()))
   ((equal? (car args) "meta")
    (write ["spec" "compile" "full" "native" "native-link"
            "native-full" "native-full-link" "native-diagnose" "clean"])
    (newline))
   ((equal? (car args) "spec")
    (pretty-print (provider-build-spec)))
   ((equal? (car args) "clean")
    (clean-provider!))
   ((equal? (car args) "compile")
    (parse-build-options (cdr args))
    (compile-native-fast-cli!))
   ((equal? (car args) "full")
    (parse-build-options (cdr args))
    (refresh-static-provider-artifacts!)
    (compile-native-fast-cli!))
   ((equal? (car args) "native")
    (parse-build-options (cdr args))
    (compile-native-fast-cli!))
   ((equal? (car args) "native-link")
    (compile-native-fast-cli!))
   ((equal? (car args) "native-full")
    (parse-build-options (cdr args))
    (refresh-static-provider-artifacts!)
    (compile-full-native-cli!))
   ((equal? (car args) "native-full-link")
    (compile-full-native-cli!))
   ((equal? (car args) "native-diagnose")
    (run-native-diagnose!))
   (else (error "Unexpected " args))))

(def (main . args)
  (ensure-gerbil-gsc!)
  (ensure-source-load-path!)
  (if (compile-command? args)
    (with-provider-build-lock!
     (lambda ()
       (ensure-package-dependencies!)
       (when (full-command? args)
         (clean-compiled-provider-artifacts!))
       (run-build! args)))
    (run-build! args)))

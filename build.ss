#!/usr/bin/env gxi
;; -*- Gerbil -*-
(import :std/make
        (only-in :std/iter for/fold)
        (only-in :std/misc/path directory-files)
        :std/misc/ports
        :std/misc/process
        (only-in :std/os/pid getpid)
        (only-in :std/os/signal kill)
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
               "build-support/gsc-wrapper-runtime.ss"
               ["build-support/gsc-wrapper-runtime.ss"
                "build-support/provider-cli.ss"])))))

;;; Boundary:
;;; - gerbil.pkg owns source/runtime roots; build.ss only materializes them for subprocesses.
;;; - The harness keeps src/ layout imports, so package roots must become local module roots.
;; : (-> Path MaybeDatum )
(def (read-package-form path)
  (and (file-exists? path)
       (call-with-input-file path read)))

;; : (-> Datum Symbol MaybeDatum )
(def (package-field-value datum field)
  (let loop ((items datum))
    (cond
     ((not (pair? items)) #f)
     ((and (eq? (car items) field)
           (pair? (cdr items)))
      (cadr items))
     (else (loop (cdr items))))))

;; : (-> Datum Boolean )
(def (source-scope-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-scope))))

;; : (-> Datum MaybeDatum )
(def (package-source-scope-form package)
  (let (policy (package-field-value package 'policy:))
    (cond
     ((source-scope-form? policy) policy)
     ((list? policy) (find source-scope-form? policy))
     (else #f))))

;; : (-> Datum Symbol (List String) )
(def (policy-string-list-field datum field)
  (let (value (package-field-value datum field))
    (cond
     ((string? value) [value])
     ((list? value) (filter string? value))
     (else '()))))

;; : (-> (List Symbol) (List String) )
(def (package-source-scope-roots fields)
  (let* ((package (read-package-form "gerbil.pkg"))
         (scope (and package (package-source-scope-form package))))
    (or (and scope
             (let loop ((fields fields))
               (and (pair? fields)
                    (let (roots (policy-string-list-field scope (car fields)))
                      (if (pair? roots)
                        roots
                        (loop (cdr fields)))))))
        '("src"))))

;; : (-> (List String) (List Path) )
(def (absolute-package-roots roots)
  (map (cut path-expand <> (current-directory)) roots))

;; : (-> Void )
(def (ensure-source-load-path!)
  (for-each add-load-path!
            (absolute-package-roots
             (package-source-scope-roots '(roots: source-roots: source-root:)))))

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
  (let (pid (package-field-value
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

(def (compile-build-support-executable! name source . maybe-dependencies)
  (let* ((binary (path-expand name (path-expand "bin" (build-prefix))))
         (tmp-binary (string-append binary ".native-tmp"))
         (tmp-exe-stub (string-append tmp-binary "__exe.scm"))
         (dependencies (if (pair? maybe-dependencies)
                         (car maybe-dependencies)
                         [source])))
    (if (native-binary-current? binary dependencies)
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

(def (compile-native-fast-binary! name source . maybe-dependencies)
  (let* ((binary (path-expand name (provider-bin-dir)))
         (tmp-binary (string-append binary ".native-tmp"))
         (tmp-exe-stub (string-append tmp-binary "__exe.scm"))
         (dependencies (if (pair? maybe-dependencies)
                         (car maybe-dependencies)
                         [source])))
    (if (native-binary-current? binary dependencies)
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
  ["src/parser/model.ss"
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

(def +native-check-static-sources+
  ["src/check-fast/gerbil-scheme-check.ss"
   "src/commands/check.ss"
   "src/constants.ss"
   "src/checker/arity.ss"
   "src/checker/core.ss"
   "src/checker/facade.ss"
   "src/checker/forms.ss"
   "src/checker/model.ss"
   "src/checker/types.ss"
   "src/checker/whitelist.ss"
   "src/parser/comment-quality.ss"
   "src/parser/control-flow.ss"
   "src/parser/core.ss"
   "src/parser/dependency-adapter-quality.ss"
   "src/parser/exports.ss"
   "src/parser/facade.ss"
   "src/parser/formals.ss"
   "src/parser/function-quality.ss"
   "src/parser/higher-order.ss"
   "src/parser/imports.ss"
   "src/parser/model.ss"
   "src/parser/owner-items.ss"
   "src/parser/package.ss"
   "src/parser/poo.ss"
   "src/parser/quality-shape.ss"
   "src/parser/query.ss"
   "src/parser/selectors.ss"
   "src/parser/source-class.ss"
   "src/parser/support.ss"
   "src/parser/syntax.ss"
   "src/parser/typed-contract-scheme.ss"
   "src/parser/runtime-contract.ss"
   "src/parser/typed-comment-metadata.ss"
   "src/parser/typed-contract.ss"
   "src/package-manager/core.ss"
   "src/package-manager/facade.ss"
   "src/extensions/model.ss"
   "src/extensions/poo-patterns.ss"
   "src/extensions/poo-inheritance.ss"
   "src/extensions/poo.ss"
   "src/extensions/core.ss"
   "src/extensions/facade.ss"
   "src/policy/model.ss"
   "src/policy/catalog.ss"
   "src/policy/prototype.ss"
   "src/policy/dependency-adapter-profile.ss"
   "src/policy/agent-support.ss"
   "src/policy/agent-style-shape.ss"
   "src/policy/agent-style-gerbil-signals.ss"
   "src/policy/agent-style.ss"
   "src/policy/agent-import.ss"
   "src/policy/agent-comment.ss"
   "src/policy/agent-source-scope.ss"
   "src/policy/agent-poo.ss"
   "src/policy/agent-dependency-adapter.ss"
   "src/policy/agent-build-support.ss"
   "src/policy/agent-build.ss"
   "src/policy/agent-alist-access.ss"
   "src/policy/agent-anonymous-pair.ss"
   "src/policy/gerbil-utils-source.ss"
   "src/policy/poo-source.ss"
   "src/policy/detection.ss"
   "src/policy/modularity.ss"
   "src/policy/agent.ss"
   "src/policy/repair.ss"
   "src/policy/core.ss"
   "src/policy/facade.ss"
   "src/protocol/support.ss"
   "src/protocol/function-quality-facts.ss"
   "src/protocol/quality-shape-facts.ss"
   "src/protocol/structural-facts.ss"
   "src/protocol/structural-index.ss"
   "src/protocol/json.ss"
   "src/support/args.ss"
   "src/support/io.ss"
   "src/types/core.ss"
   "src/types/env.ss"
   "src/types/facade.ss"
   "src/types/findings.ss"
   "src/types/model.ss"
   "src/types/signatures.ss"
   "src/types/subtyping.ss"
   "src/types/validation.ss"])

(def (refresh-native-fast-static-artifacts!)
  (display "... refresh native fast static artifacts\n")
  (set-provider-compile-env!)
  (for-each compile-static-provider-source!
            +native-fast-static-sources+))

(def (refresh-native-check-static-artifacts!)
  (display "... refresh native check static artifacts\n")
  (set-provider-compile-env!)
  (for-each compile-static-provider-source!
            (append +native-fast-static-sources+
                    +native-check-static-sources+)))

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
  (refresh-native-check-static-artifacts!)
  (compile-native-fast-binary!
   "gerbil-scheme-search-extension"
   "src/search-fast/gerbil-scheme-search-extension.ss")
  (compile-native-fast-binary!
   "gerbil-scheme-search-pattern"
   "src/search-fast/gerbil-scheme-search-pattern.ss")
  (compile-native-fast-binary!
   "gerbil-scheme-check"
   "src/check-fast/gerbil-scheme-check.ss"
   (append +native-fast-static-sources+
           +native-check-static-sources+))
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
  (setenv "GERBIL_LOADPATH"
          (string-join
           (absolute-package-roots
            (package-source-scope-roots '(roots: source-roots: source-root:)))
           ":")))

(def (build-source-directory? path)
  (eq? (file-type path) 'directory))

(def (static-provider-source-file? path)
  (equal? (path-extension path) ".ss"))

(def (top-level-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))))

(def (top-level-test-files)
  (map (lambda (entry) (path-expand entry "t"))
       (filter top-level-test-file?
               (sort (directory-files "t") string<?))))

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
         (> target-time source-time))))

(def (target-current-for-sources? target-time sources)
  (cond
   ((not target-time) #f)
   ((null? sources) #t)
   (else
    (let (source-time (file-mtime-seconds (car sources)))
      (and source-time
           (> target-time source-time)
           (target-current-for-sources? target-time (cdr sources)))))))

(def (file-current-for-sources? target sources)
  (target-current-for-sources?
   (file-mtime-seconds target)
   (if (list? sources) sources [sources])))

(def (native-binary-current? binary sources)
  (and (file-current-for-sources? binary sources)
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

(def (run-provider-tests!)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" (current-directory)))
  (setenv "GERBIL_LOADPATH"
          (string-join
           (absolute-package-roots
            (package-source-scope-roots '(runtime-roots: runtime-root: roots:)))
           ":"))
  (let (tests (top-level-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (invoke "gxtest" tests))))

(def (run-build! args)
  (cond
   ((null? args) (make-provider! '()))
   ((equal? (car args) "meta")
    (write ["spec" "compile" "full" "native" "native-link"
            "native-full" "native-full-link" "native-diagnose" "clean" "test"])
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
   ((equal? (car args) "test")
    (run-provider-tests!))
   (else (error "Unexpected " args))))

(def (main . args)
  (ensure-gerbil-gsc!)
  (ensure-source-load-path!)
  (if (package-dependency-command? args)
    (with-provider-build-lock!
     (lambda ()
       (ensure-package-dependencies!)
       (when (and (compile-command? args)
                  (full-command? args))
         (clean-compiled-provider-artifacts!))
       (run-build! args)))
    (run-build! args)))

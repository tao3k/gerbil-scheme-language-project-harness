;;; -*- Gerbil -*-
;;; Native launcher for per-command Gerbil Scheme harness executables.

(import :gerbil/gambit
        (only-in :constants +help+)
        (only-in :search-light-launcher try-search-light-main)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process process-status run-process)
        (only-in :std/source this-source-file))
(export main
        command-line-args
        provider-command-line-args)

;;; Install boundary:
;;; - The native launcher is intentionally package-local and relocatable across
;;;   installs that preserve the package tree. It records the source package
;;;   root at build time so a lightweight `.bin/gslph` can delegate to source
;;;   command modules without importing the whole harness at executable startup.
;; : String
(def +embedded-package-root+
  (path-normalize (path-expand ".." (path-directory (this-source-file)))))

;;; Command binary names are optional acceleration points, not the canonical
;;; contract. If future builds ship per-command siblings beside `gslph`, the
;;; launcher uses them; otherwise it keeps the same public CLI through the
;;; source-mode command dispatcher.
;; : (List (Pair String String))
(def +command-binaries+
  '(("query" . "gslph-query")
    ("check" . "gslph-check")
    ("bench" . "gslph-bench")
    ("evidence" . "gslph-evidence")
    ("agent" . "gslph-agent")
    ("guide" . "gslph-guide")
    ("info" . "gslph-info")))

;; : (List String)
(def +source-commands+
  '("search"
    "query"
    "check"
    "bench"
    "evidence"
    "agent"
    "guide"
    "info"))

;; : (List String)
(def +commands+
  '("search" "query" "check" "bench" "evidence" "agent" "guide" "info"
    "help" "-h" "--help"))

;; : (List String)
(def +launcher-names+
  '("gxi" "gslph" "gerbil-scheme-harness"))

;;; Launcher argv boundary:
;;; - Keep this tiny normalization local so the release launcher does not
;;;   statically link the full source command dispatcher.
;; : (-> (List String) (List String))
(def (command-line-args argv)
  (or (command-line-command-tail argv)
      (strip-launcher-frames argv)))

;; : (-> (List String) (List String))
(def provider-command-line-args command-line-args)

;; : (-> (List String) (Maybe (List String)))
(def (command-line-command-tail argv)
  (match argv
    ([] #f)
    ([arg . rest]
     (if (member arg +commands+)
       argv
       (command-line-command-tail rest)))))

;; : (-> (List String) (List String))
(def (strip-launcher-frames argv)
  (match argv
    ([] [])
    ([arg . rest]
     (if (launcher-frame? arg)
       (strip-launcher-frames rest)
       argv))))

;; : (-> String Boolean)
(def (launcher-frame? arg)
  (or (launcher-name? arg)
      (launcher-binary-path? arg)
      (launcher-script-path? arg)))

;; : (-> String Boolean)
(def (launcher-name? arg)
  (member arg +launcher-names+))

;; : (-> String Boolean)
(def (launcher-binary-path? arg)
  (or (string-suffix? "/gxi" arg)
      (string-suffix? "/gslph" arg)
      (string-suffix? "/gerbil-scheme-harness" arg)))

;; : (-> String Boolean)
(def (launcher-script-path? arg)
  (or (equal? arg "src/cli.ss")
      (string-suffix? "/src/cli.ss" arg)))

;; : (-> String (U String #f))
(def (command-binary-name command)
  (let (entry (assoc command +command-binaries+))
    (and entry (cdr entry))))

;; : (-> String Boolean)
(def (known-source-command? command)
  (and (member command +source-commands+) #t))

;;; Path boundary:
;;; - Optional command binaries are discovered only beside the active launcher,
;;;   keeping installs self-contained under the chosen bin directory.
;;; - No PATH probing happens here; PATH remains the caller's concern at the
;;;   install-wrapper level.
;; : (-> String String)
(def (sibling-binary-path binary-name)
  (path-expand binary-name (path-directory (car (command-line)))))

;;; Process boundary:
;;; - Invoke Gerbil directly with argv vectors. Do not construct a shell command;
;;;   command arguments are data all the way to the child process.
;;; - Capture and replay stdout/stderr through Gerbil ports so the launcher can
;;;   return the child status while preserving command output for hooks/tests.
;; : (-> (List String) Integer)
(def (run-process/relay argv)
  (run-process argv
               stdin-redirection: #f
               stdout-redirection: #t
               stderr-redirection: #t
               check-status: #f
               coprocess:
               (lambda (process)
                 (let (output (read-all-as-string process))
                   (display output)
                   (process-status process)))))

;;; Binary dispatch:
;;; - Sibling command binaries receive only the subcommand tail because their
;;;   executable name already identifies the command owner.
;; : (-> String (List String) Integer)
(def (run-command-binary binary args)
  (run-process/relay (cons binary args)))

;;; Source fallback:
;;; - Keep native build cheap by avoiding top-level imports of every policy,
;;;   parser, and command module from the executable image.
;;; - The fallback still executes the same `:cli` dispatcher through `gxi`; it
;;;   is a portability path for package installs, not a shell-script substitute.
;; : (-> (List String) Integer)
(def (run-source-command args)
  (run-process/relay
   ["gxi" "-e" (source-command-expression (normalize-source-command-args args))]))

;;; Source CLI compatibility:
;;; - Public ASP search commands use `--workspace PROJECT_ROOT`.
;;; - The source dispatcher still accepts search workspace as a trailing
;;;   positional PROJECT_ROOT and does not consume `--view`. Normalize only this
;;;   launcher fallback boundary so canonical `gslph` stays source-compatible
;;;   without depending on a sibling search binary.
;; : (-> (List String) (List String))
(def (normalize-source-command-args args)
  (if (and (pair? args) (equal? (car args) "search"))
    (cons "search" (normalize-search-workspace-args (cdr args) [] #f))
    args))

;; : (-> (List String) (List String) (U String #f) (List String))
(def (normalize-search-workspace-args args kept workspace)
  (cond
   ((null? args)
    (append (reverse kept)
            (if workspace (list workspace) [])))
   ((and (equal? (car args) "--workspace")
         (pair? (cdr args)))
    (normalize-search-workspace-args (cddr args) kept (cadr args)))
   ((and (equal? (car args) "--view")
         (pair? (cdr args)))
    (normalize-search-workspace-args (cddr args) kept workspace))
   (else
    (normalize-search-workspace-args (cdr args) (cons (car args) kept) workspace))))

;;; Expression boundary:
;;; - The only generated expression is a small Gerbil bootstrap form.
;;; - Package paths and argv are serialized with `write`, then re-read as Scheme
;;;   data, so user arguments cannot splice forms into the command expression.
;; : (-> (List String) String)
(def (source-command-expression args)
  (string-append
   "(begin (add-load-path! "
   (datum->expression-string (path-expand "src" +embedded-package-root+))
   ") (eval (quote (import :cli)))"
   " (exit (apply (eval (quote main)) "
   "(quote "
   (datum->expression-string args)
   ")"
   ")))"))

;;; Datum rendering:
;;; - Use `write` against a string port because the bootstrap expression needs
;;;   Gerbil-readable data, not display-oriented text.
;;; - `cut` fixes only the output port argument; the datum remains the single
;;;   explicit input, so callers cannot hide extra evaluation behavior here.
;; : (-> Datum String)
;; | type Datum = (U String Symbol Integer Boolean Null Pair)
(def (datum->expression-string value)
  (call-with-output-string "" (cut write value <>)))

;;; Public CLI:
;;; - Help stays in-process so `gslph --help` has no startup dependency on the
;;;   command graph.
;;; - Real subcommands prefer sibling binaries when present, then fall back to
;;;   the source dispatcher with the original command token preserved.
;; : (-> (List String) Boolean)
(def (help-args? args)
  (or (null? args)
      (and (null? (cdr args))
           (member (car args) '("-h" "--help" "help")))))

;; : (-> Integer Integer)
(def (emit-help status)
  (display +help+)
  status)

;; : (-> String (List String) (List String) Integer)
(def (dispatch-command command rest args)
  (or (try-native-search-command command rest)
      (dispatch-source-command command rest args)))

;; : (-> String (List String) (U Integer #f))
(def (try-native-search-command command rest)
  (and (equal? command "search")
       (try-search-light-main rest)))

;; : (-> String (List String) (List String) Integer)
(def (dispatch-source-command command rest args)
  (if (known-source-command? command)
    (or (try-sibling-command-binary command rest)
        (run-source-command args))
    (emit-help 2)))

;; : (-> String (List String) (U Integer #f))
(def (try-sibling-command-binary command rest)
  (let (binary-name (command-binary-name command))
    (and binary-name
         (let (binary (sibling-binary-path binary-name))
           (and (file-exists? binary)
                (run-command-binary binary rest))))))

;; : (-> (List String) Integer)
(def (main . args)
  (cond
   ((help-args? args)
    (emit-help 0))
   ((pair? args)
    (dispatch-command (car args) (cdr args) args))
   (else
    (emit-help 2))))

;;; -*- Gerbil -*-
;;; Native launcher for per-command Gerbil Scheme harness executables.

(import :gerbil/gambit
        (only-in :cli command-line-args provider-command-line-args)
        (only-in :constants +help+)
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
  '(("search" . "gslph-search")
    ("query" . "gslph-query")
    ("check" . "gslph-check")
    ("bench" . "gslph-bench")
    ("evidence" . "gslph-evidence")
    ("agent" . "gslph-agent")
    ("guide" . "gslph-guide")
    ("info" . "gslph-info")))

;; : (-> String (U String #f))
(def (command-binary-name command)
  (let (entry (assoc command +command-binaries+))
    (and entry (cdr entry))))

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
   ["gxi" "-e" (source-command-expression args)]))

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
;; : (-> (List String) Integer)
(def (main . args)
  (match args
    ([] (display +help+) 0)
    (["-h"] (display +help+) 0)
    (["--help"] (display +help+) 0)
    (["help"] (display +help+) 0)
    ([command . rest]
     (let (binary-name (command-binary-name command))
       (if binary-name
         (let (binary (sibling-binary-path binary-name))
           (if (file-exists? binary)
             (run-command-binary binary rest)
             (run-source-command args)))
         (begin
           (display +help+)
           2))))
    (else
     (display +help+)
     2)))

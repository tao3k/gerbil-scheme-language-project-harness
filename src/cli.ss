;;; -*- Gerbil -*-
;;; Thin command dispatcher for the Gerbil Scheme project harness.

(import (only-in :constants +help+))
(export main
        command-line-args
        provider-command-line-args)

;; (List String)
(def +commands+
  '("search" "query" "check" "bench" "evidence" "agent" "guide" "info"
    "help" "-h" "--help"))

;; (List String)
(def +launcher-names+
  '("gxi" "gslph" "gerbil-scheme-harness"))

;;; Dispatch table:
;;; - Keep this table declarative so the public subcommand surface is visible
;;;   without importing the policy/parser/search graph at module load time.
;;; - Each entry points to the compiled module id plus exported command binding;
;;;   dispatch loads exactly one command module after argv normalization.
;; (List CommandDispatch)
(def +command-dispatch+
  '(("search" "gslph/src/commands/search" gslph/src/commands/search#search-main)
    ("query" "gslph/src/commands/query" gslph/src/commands/query#query-main)
    ("check" "gslph/src/commands/check" gslph/src/commands/check#check-main)
    ("bench" "gslph/src/commands/bench" gslph/src/commands/bench#bench-main)
    ("evidence" "gslph/src/commands/evidence" gslph/src/commands/evidence#evidence-main)
    ("agent" "gslph/src/commands/agent" gslph/src/commands/agent#agent-main)
    ("guide" "gslph/src/commands/guide" gslph/src/commands/guide#guide-main)
    ("info" "gslph/src/commands/info" gslph/src/commands/info#info-main)))

;;; Boundary:
;;; - command-line-args is the single argv normalization boundary for direct
;;;   gxi scripts, shebang scripts, installed binaries, and compatibility
;;;   wrappers.
;;; - The invariant is semantic: main must receive the provider subcommand as
;;;   argv[0], regardless of whether command-line includes executable or script
;;;   path frames before it.
;;; Risk:
;;; - Fixed-position trimming can drop "check" before check-main and turn valid
;;;   agent CLI calls into generic usage output, hiding real policy findings.
;; : (-> (List String) (List String) )
(def (command-line-args argv)
  (or (command-line-command-tail argv)
      (strip-launcher-frames argv)))

;; : (-> (List String) (List String) )
(def provider-command-line-args command-line-args)

;;; Boundary:
;;; - The command-tail scan finds valid subcommands even when launcher wrappers
;;;   include host-specific absolute paths before the semantic argv starts.
;;; - Return #f instead of [] on miss so unknown commands remain visible to
;;;   main and keep the invalid-command exit status.
;; : (-> (List String) (Maybe (List String)) )
(def (command-line-command-tail argv)
  (match argv
    ([] #f)
    ([arg . rest]
     (if (member arg +commands+)
       argv
       (command-line-command-tail rest)))))

;;; Boundary:
;;; - Only executable/script frames are stripped after no valid subcommand was
;;;   found. The first non-launcher token is a user command, even if unknown.
;;; - This keeps no-argument wrappers as [] while preserving usage errors such
;;;   as "gerbil-scheme-harness bogus".
;; : (-> (List String) (List String) )
(def (strip-launcher-frames argv)
  (match argv
    ([] [])
    ([arg . rest]
     (if (launcher-frame? arg)
       (strip-launcher-frames rest)
       argv))))

;;; Boundary:
;;; - Keep launcher-frame families named so adding a runtime entrypoint does
;;;   not grow an opaque inline boolean condition.
;; : (-> String Boolean )
(def (launcher-frame? arg)
  (or (launcher-name? arg)
      (launcher-binary-path? arg)
      (launcher-script-path? arg)))

;; : (-> String Boolean )
(def (launcher-name? arg)
  (member arg +launcher-names+))

;; : (-> String Boolean )
(def (launcher-binary-path? arg)
  (or (string-suffix? "/gxi" arg)
      (string-suffix? "/gslph" arg)
      (string-suffix? "/gerbil-scheme-harness" arg)))

;; : (-> String Boolean )
(def (launcher-script-path? arg)
  (or (equal? arg "src/cli.ss")
      (string-suffix? "/src/cli.ss" arg)))

;;; Boundary:
;;; - Runtime command modules are loaded only after argv dispatch selects one.
;;; - `load-module` uses compiled module ids so native executables do not need
;;;   the expander to evaluate import forms at command dispatch time.
;; : (-> Command (List String) ExitCode )
(def (dispatch-command command rest)
  (let (entry (find-command-dispatch command +command-dispatch+))
    (if entry
      (let (command-main
            (begin
              (ensure-runtime-loader!)
              (dynamic-command-main (cadr entry) (caddr entry))))
        (command-main rest))
      (begin
        (display +help+)
        2))))

;;; Runtime boundary:
;;; - Dynamically loaded Gerbil modules emit top-level `load-module` calls for
;;;   their own dependencies.
;;; - Native executable startup does not always expose the Gerbil loader in the
;;;   eval namespace, so install this module's loader binding before dispatch.
;; : (-> Unit )
(def (ensure-runtime-loader!)
  (##global-var-set! (##make-global-var 'load-module) load-module))

;;; Dispatch lookup:
;;; - This match is the only linear scan over the dispatch table; it stops on
;;;   the first command-name match and returns #f on miss so unknown commands
;;;   keep flowing to the public usage/error branch.
;;; - Do not collapse this into eval-by-name: the table is the audit boundary
;;;   that prevents user argv from selecting arbitrary modules.
;; : (-> Command (List CommandDispatch) MaybeCommandDispatch )
(def (find-command-dispatch command entries)
  (match entries
    ([] #f)
    ([entry . rest]
     (if (equal? command (car entry))
       entry
       (find-command-dispatch command rest)))))

;;; Dynamic load boundary:
;;; - Keep the module id and binding id as separate table fields so the command
;;;   graph stays explicit and audit-friendly.
;;; - Evaluation is limited to the exported binding selected from the table;
;;;   user argv never becomes a module path or binding expression.
;; : (-> ModulePath BindingId Procedure )
(def (dynamic-command-main module-id binding-id)
  (load-module module-id)
  (eval binding-id))

;;; Invariant:
;;; - main owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> (List String) ExitCode )
(def (main . args)
  (match args
    ([] (display +help+) 0)
    (["-h"] (display +help+) 0)
    (["--help"] (display +help+) 0)
    (["help"] (display +help+) 0)
    ([command . rest] (dispatch-command command rest))
    (else
     (display +help+)
     2)))

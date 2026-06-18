;;; -*- Gerbil -*-
;;; Thin command dispatcher for the Gerbil Scheme project harness.

(import (only-in :commands/agent agent-main)
        (only-in :commands/bench bench-main)
        (only-in :commands/check check-main)
        (only-in :commands/evidence evidence-main)
        (only-in :commands/guide guide-main)
        (only-in :commands/info info-main)
        (only-in :commands/query query-main)
        (only-in :commands/search search-main)
        (only-in :constants +help+))
(export main
        provider-command-line-args)

;; (List String)
(def +provider-commands+
  '("search" "query" "check" "bench" "evidence" "agent" "guide" "info"
    "help" "-h" "--help"))

;; (List String)
(def +provider-launcher-names+
  '("gxi" "gerbil-scheme-harness"))

;;; Boundary:
;;; - provider-command-line-args is the single argv normalization boundary for
;;;   direct gxi scripts, shebang scripts, and generated provider wrappers.
;;; - The invariant is semantic: main must receive the provider subcommand as
;;;   argv[0], regardless of whether command-line includes executable or script
;;;   path frames before it.
;;; Risk:
;;; - Fixed-position trimming can drop "check" before check-main and turn valid
;;;   agent CLI calls into generic usage output, hiding real policy findings.
;; : (-> (List String) (List String) )
(def (provider-command-line-args argv)
  (or (provider-command-line-command-tail argv)
      (strip-provider-launcher-frames argv)))

;;; Boundary:
;;; - The command-tail scan finds valid subcommands even when launcher wrappers
;;;   include host-specific absolute paths before the semantic argv starts.
;;; - Return #f instead of [] on miss so unknown commands remain visible to
;;;   main and keep the invalid-command exit status.
;; : (-> (List String) (Maybe (List String)) )
(def (provider-command-line-command-tail argv)
  (match argv
    ([] #f)
    ([arg . rest]
     (if (member arg +provider-commands+)
       argv
       (provider-command-line-command-tail rest)))))

;;; Boundary:
;;; - Only executable/script frames are stripped after no valid subcommand was
;;;   found. The first non-launcher token is a user command, even if unknown.
;;; - This keeps no-argument wrappers as [] while preserving usage errors such
;;;   as "gerbil-scheme-harness bogus".
;; : (-> (List String) (List String) )
(def (strip-provider-launcher-frames argv)
  (match argv
    ([] [])
    ([arg . rest]
     (if (provider-launcher-frame? arg)
       (strip-provider-launcher-frames rest)
       argv))))

;; : (-> (String) Bool )
(def (provider-launcher-frame? arg)
  (or (member arg +provider-launcher-names+)
      (string-suffix? "/gxi" arg)
      (string-suffix? "/gerbil-scheme-harness" arg)
      (string-suffix? "/gerbil-scheme-harness.ss" arg)))

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
    (["search" . rest] (search-main rest))
    (["query" . rest] (query-main rest))
    (["check" . rest] (check-main rest))
    (["bench" . rest] (bench-main rest))
    (["evidence" . rest] (evidence-main rest))
    (["agent" . rest] (agent-main rest))
    (["guide" . rest] (guide-main rest))
    (["info" . rest] (info-main rest))
    (else
     (display +help+)
     2)))

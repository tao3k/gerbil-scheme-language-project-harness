#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Build-time materialization for non-code guide rows.

(import :gerbil/gambit
        :commands/guide-sections)

(export main)

(def +guide-static-files+
  [["gerbil-scheme-guide-basic.txt" []]
   ["gerbil-scheme-guide-all.txt" ["--all"]]
   ["gerbil-scheme-guide-policy.txt" ["--policy"]]
   ["gerbil-scheme-guide-extensions.txt" ["--extensions"]]
   ["gerbil-scheme-guide-downstream.txt" ["--downstream"]]
   ["gerbil-scheme-guide-poo.txt" ["--poo"]]
   ["gerbil-scheme-guide-exemplars.txt" ["--exemplars"]]])

;;; Boundary:
;;; - Guide row ownership stays in :commands/guide-sections.
;;; - This build helper only materializes the selected static projections.
;; : (-> OutputDirectory GuideFileSpec Unit)
(def (write-guide-file! output-dir spec)
  (let ((path (path-expand (car spec) output-dir))
        (args (cadr spec)))
    (call-with-output-file path
      (lambda (out)
        (for-each
         (lambda (line)
           (display line out)
           (newline out))
         (guide-section-lines-for args))))))

;;; Boundary:
;;; - build.ss invokes this script as a materializer, not as CLI policy logic.
;;; - Keep guide selection data-driven through +guide-static-files+.
;; main
;;   : (-> OutputDirectory ExitCode)
;;   | doc m%
;;       `main output-dir` writes every static guide text artifact into
;;       `output-dir` and returns zero after materialization completes.
;;
;;       # Examples
;;       ```scheme
;;       (main ".run/generated-guide")
;;       ;; => 0
;;       ```
;;     %
(def (main output-dir)
  (create-directory* output-dir)
  (for-each (lambda (spec) (write-guide-file! output-dir spec))
            +guide-static-files+)
  0)

(exit (apply main (cddr (command-line))))

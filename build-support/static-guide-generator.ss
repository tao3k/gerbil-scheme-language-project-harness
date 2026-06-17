#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Build-time materialization for non-code guide rows.

(import :gerbil/gambit
        :commands/guide-sections)

(def +guide-static-files+
  [["gerbil-scheme-guide-basic.txt" []]
   ["gerbil-scheme-guide-all.txt" ["--all"]]
   ["gerbil-scheme-guide-policy.txt" ["--policy"]]
   ["gerbil-scheme-guide-extensions.txt" ["--extensions"]]
   ["gerbil-scheme-guide-downstream.txt" ["--downstream"]]
   ["gerbil-scheme-guide-poo.txt" ["--poo"]]
   ["gerbil-scheme-guide-exemplars.txt" ["--exemplars"]]])

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

(def (main output-dir)
  (create-directory* output-dir)
  (for-each (lambda (spec) (write-guide-file! output-dir spec))
            +guide-static-files+)
  0)

(exit (apply main (cddr (command-line))))

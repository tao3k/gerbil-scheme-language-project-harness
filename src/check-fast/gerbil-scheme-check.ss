;;; -*- Gerbil -*-
;;; Native check command entrypoint.
;;; Keeps `check` off the generic gxi harness runtime path.

(import :gerbil/gambit
        :commands/check
        (only-in :std/srfi/13 string-suffix?))
(export main)

;; : (-> MaybePathString Boolean)
(def (source-script-path? value)
  (and (string? value)
       (string-suffix? ".ss" value)))

;; : (-> (List String))
(def (entry-args)
  (let (args (command-line))
    (if (and (pair? args)
             (pair? (cdr args))
             (source-script-path? (cadr args)))
      (cddr args)
      (cdr args))))

;; : (-> (List String) Integer)
(def (main . args)
  (check-main args))

(exit (apply main (entry-args)))

#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :std/srfi/13 string-suffix?)
        :cli)

(def (source-script-path? value)
  (and (string? value)
       (string-suffix? ".ss" value)))

(def (entry-args)
  (let (args (command-line))
    (if (and (pair? args)
             (pair? (cdr args))
             (source-script-path? (cadr args)))
      (cddr args)
      (cdr args))))

(exit (apply main (entry-args)))

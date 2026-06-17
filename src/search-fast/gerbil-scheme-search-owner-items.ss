;;; -*- Gerbil -*-
;;; Fast-path entrypoint for owner item materialization.

(import :gerbil/gambit
        :commands/search-owner-items
        (only-in :std/sugar match))

(export main)

;;; Script-path boundary:
;;; - gxi may leave the source script path in argv.
;;; - Only .ss path-looking values are stripped as launcher metadata.
;; Boolean <- ArgValue
(def (source-script-path? value)
  (and (string? value)
       (let (length (string-length value))
         (and (fx>= length 3)
              (equal? (substring value (- length 3) length) ".ss")))))

;;; Arg normalization:
;;; - Fast-path binaries accept both full `search owner` and owner-local forms.
;;; - The command owner receives normalized args without launcher noise.
;; Args <- CommandLine
(def (search-owner-items-args)
  (let* ((raw (command-line))
         (args (if (and (pair? raw)
                        (pair? (cdr raw))
                        (source-script-path? (cadr raw)))
                 (cddr raw)
                 (cdr raw))))
    (if (and (pair? args)
             (equal? (car args) "search"))
      (cdr args)
      args)))

;;; Dispatch boundary:
;;; - This wrapper only accepts owner-items shape.
;;; - All parser and rendering behavior stays in :commands/search-owner-items.
;; ExitCode <- Args
(def (owner-items-main args)
  (match args
    (["owner" . rest]
     (emit-owner-items-command rest))
    (else
     (error "fast owner-items requires `search owner <path> items`" args))))

;;; Process entry:
;;; - main keeps the exported entrypoint testable.
;;; - Script execution below uses the normalized argv path.
;; ExitCode <- Args
(def (main . args)
  (owner-items-main args))

(exit (owner-items-main (search-owner-items-args)))

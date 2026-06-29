;;; -*- Gerbil -*-
;;; Boundary:
;;; - read-forms owns the port state.
;;; - source-forms owns the file boundary.
;;; - Def-symbol selection stays in the public combinator boundary.
(package: sample/source-reader)
(import (only-in :std/sugar filter-map))
(export source-forms local-def-symbols)

;; def-symbol
;;   : (-> Form (Maybe Symbol))
;;   | doc m%
;;       `def-symbol` extracts the public definition symbol from one source
;;       form and leaves traversal to the caller.
;;
;;       # Examples
;;
;;       ```scheme
;;       (def-symbol '(def (run x) x))
;;       ;; => run
;;       ```
;;     %
(def (def-symbol form)
  (and (pair? form)
       (eq? (car form) 'def)
       (pair? (cdr form))
       (let (head (cadr form))
         (cond
          ((symbol? head) head)
          ((and (pair? head) (symbol? (car head))) (car head))
          (else #f)))))

;; read-forms
;;   : (-> Port (List Form))
;;   | warning owns port/read state; callers should not mix this loop with
;;       file path handling, selection, or projection logic
;;   | doc m%
;;       `read-forms` is the only EOF loop. It returns source forms in port
;;       order so file helpers can stay a direct IO boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (read-forms port)
;;       ;; => forms
;;       ```
;;     %
(def (read-forms port)
  (let loop ((forms []))
    (let (form (read port))
      (if (eof-object? form)
        (reverse forms)
        (loop (cons form forms))))))

;; source-forms
;;   : (-> Path (List Form))
;;   | doc m%
;;       `source-forms` binds files to the reader helper without embedding the
;;       EOF loop in the file boundary.
;;     %
(def (source-forms file)
  (call-with-input-file file read-forms))

;; local-def-symbols
;;   : (-> Path (List Symbol))
;;   | doc m%
;;       `local-def-symbols` composes the reader boundary with `filter-map` so
;;       definition selection is visible to parser-owned policy evidence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (local-def-symbols "src/reader/core.ss")
;;       ;; => (def-symbol read-forms source-forms local-def-symbols)
;;       ```
;;     %
(def (local-def-symbols file)
  (filter-map def-symbol (source-forms file)))

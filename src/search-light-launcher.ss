;;; -*- Gerbil -*-
;;; Native search launcher with fast package/topology seed paths.

(import :gerbil/gambit
        (only-in :commands/search-prime-light
                 search-prime-light-main
                 search-workspace-scope-light-main)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process process-status run-process)
        (only-in :std/source this-source-file)
        (only-in :std/sugar match))

(export main)

;; : String
(def +embedded-package-root+
  (path-normalize (path-expand ".." (path-directory (this-source-file)))))

;;; Process boundary:
;;; - Fast package/topology seed views stay in native code.
;;; - Other search views delegate to the existing source command module so this
;;;   launcher does not import the full parser/search graph at startup.
;; : (-> (List String) Integer)
(def (main . args)
  (cond
   ((search-prime-light-argv? args)
    (search-prime-light-main args))
   ((search-workspace-scope-light-argv? args)
    (search-workspace-scope-light-main args))
   (else
    (run-source-search args))))

;; : (-> Args Boolean )
(def (search-prime-light-argv? args)
  (match args
    (["prime" . rest]
     (and (search-prime-seeds-view? rest)
          (not (arg-present? "--json" rest))))
    (else #f)))

;; : (-> Args Boolean )
(def (search-workspace-scope-light-argv? args)
  (match args
    (["workspace-scope" . rest]
     (not (arg-present? "--json" rest)))
    (else #f)))

;; : (-> Args Boolean )
(def (search-prime-seeds-view? args)
  (or (equal? (option-value "--view" args) "seeds")
      (arg-present? "seeds" args)))

;; : (-> String Args Boolean )
(def (arg-present? needle args)
  (match args
    ([] #f)
    ([arg . rest]
     (or (equal? arg needle)
         (arg-present? needle rest)))))

;; : (-> String Args (Maybe String) )
(def (option-value needle args)
  (match args
    ([] #f)
    ([arg value . rest]
     (if (equal? arg needle)
       value
       (option-value needle (cons value rest))))
    ([_] #f)))

;; : (-> (List String) Integer)
(def (run-source-search args)
  (run-process/relay
   ["gxi" "-e" (source-search-expression args)]))

;; : (-> (List String) String)
(def (source-search-expression args)
  (string-append
   "(begin (add-load-path! "
   (datum->expression-string (path-expand "src" +embedded-package-root+))
   ") (eval (quote (import :commands/search)))"
   " (exit ((eval (quote search-main)) "
   "(quote "
   (datum->expression-string args)
   ")"
   ")))"))

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

;; : (-> Datum String)
(def (datum->expression-string value)
  (call-with-output-string "" (cut write value <>)))

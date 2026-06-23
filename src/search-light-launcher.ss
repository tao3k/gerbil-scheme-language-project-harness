;;; -*- Gerbil -*-
;;; Native search launcher with fast package/topology seed paths.

(import :gerbil/gambit
        (only-in :commands/search-prime-light
                 search-prime-light-main
                 search-workspace-scope-light-main))

(export main
        try-search-light-main)

(def +search-help+
  "gslph search - Gerbil Scheme native fast search\n\nUsage:\n  gslph search prime [--view seeds] [--workspace PROJECT_ROOT]\n  gslph search workspace-scope [--workspace PROJECT_ROOT]\n")

;;; Process boundary:
;;; - Fast package/topology seed views stay in native code.
;;; - Other search views fail closed with a granular example instead of
;;;   silently spawning `gxi` and turning search into a slow source load.
;; : (-> (List String) (U Integer #f))
(def (try-search-light-main args)
  (cond
   ((help-argv? args)
    (display +search-help+)
    0)
   ((search-prime-light-argv? args)
    (search-prime-light-main args))
   ((search-workspace-scope-light-argv? args)
    (search-workspace-scope-light-main args))
   (else
    #f)))

;; : (-> (List String) Integer)
(def (main . args)
  (or (try-search-light-main args)
      (emit-unsupported-native-search args)))

;; : (-> Args Boolean)
(def (help-argv? args)
  (or (null? args)
      (and (null? (cdr args))
           (or (equal? (car args) "-h")
               (equal? (car args) "--help")
               (equal? (car args) "help")))))

;; : (-> Args Boolean )
(def (search-prime-light-argv? args)
  (and (pair? args)
       (equal? (car args) "prime")
       (let (rest (cdr args))
         (and (search-prime-seeds-view? rest)
              (not (arg-present? "--json" rest))))))

;; : (-> Args Boolean )
(def (search-workspace-scope-light-argv? args)
  (and (pair? args)
       (equal? (car args) "workspace-scope")
       (not (arg-present? "--json" (cdr args)))))

;; : (-> Args Boolean )
(def (search-prime-seeds-view? args)
  (or (equal? (option-value "--view" args) "seeds")
      (arg-present? "seeds" args)))

;; : (-> String Args Boolean )
(def (arg-present? needle args)
  (and (pair? args)
       (or (equal? (car args) needle)
           (arg-present? needle (cdr args)))))

;; : (-> String Args (Maybe String) )
(def (option-value needle args)
  (cond
   ((null? args) #f)
   ((and (pair? (cdr args))
         (equal? (car args) needle))
    (cadr args))
   (else
    (option-value needle (cdr args)))))

;; : (-> (List String) Integer)
(def (emit-unsupported-native-search args)
  (display "gslph search supports native fast seed views only; use `gslph search prime --view seeds --workspace .` or `gslph search workspace-scope --workspace .`.\n"
           (current-error-port))
  64)

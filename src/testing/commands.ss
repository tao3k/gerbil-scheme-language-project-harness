;;; Declarative command surface for downstream project test scripts.
;;; The Testing Framework owns bootstrap, receipt, and exit-status sequencing.
(export define-project-test)

;; define-project-test
;;   kind: syntax
;; The receipt predicate is the specialized exit-status boundary; bootstrap and
;; project construction remain outside it so selected runs keep one receipt.
;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)]))
;; : (-> (List Path) Integer)
;;   | doc m%
;;       Define one selected-test runner from project bootstrap, construction,
;;       execution, and receipt-status procedures.
;;
;;       # Examples
;;
;;       ```scheme
;;       (define-project-test run-selected-tests
;;         bootstrap!: prepare!
;;         project: make-project
;;         run: run-files
;;         ok?: receipt-ok?)
;;       ```
;;
;;       Result: the generated runner returns 0 for an accepted receipt and 1
;;       when the supplied receipt predicate rejects the selected test run.
;;     %
;; define-project-test
;; : (-> [Path] Integer)
;; | doc m%
;;   Define a project-local `test!` command that bootstraps the selected test
;;   files and returns the resulting process exit status.
;;   # Examples
;;   ```scheme
;;   (test! ["t/parser-memory-stability-test.ss"])
;;   ;; => 0
;;   ```
(defrules define-project-test ()
  ((_ test!
      project: project
      run: run
      ok?: ok?)
   (def (test! files)
     (let (receipt
           (run (project) files))
       (if (ok? receipt) 0 1))))
  ((_ test!
      bootstrap!: bootstrap!
     project: project
     run: run
     ok?: ok?)
   ;; The receipt predicate is the specialized exit-status boundary; bootstrap
   ;; and project construction stay outside the selected-test decision.
   ;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)]))
   ;; : (-> (List Path) Integer)
   (def (test! files)
     (bootstrap!)
     (let (receipt
           (run (project) files))
       (if (ok? receipt) 0 1)))))

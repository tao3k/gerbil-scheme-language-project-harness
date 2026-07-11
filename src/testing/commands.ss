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
(defrules define-project-test ()
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

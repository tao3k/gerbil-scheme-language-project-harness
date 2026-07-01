;;; -*- Gerbil -*-
;;; Tiny gxtest adapter for downstream packages that depend on this harness.

(import :gerbil/gambit
        (for-syntax :gerbil/gambit
                    :gerbil/expander
                    :std/stxutil)
        (only-in :std/test check test-case test-suite)
        (only-in "./gxtest-report"
                 display-project-policy-report
                 gxtest-report-agent-repair
                 gxtest-report-definitions
                 gxtest-report-files
                 gxtest-report-finding-count
                 gxtest-report-findings
                 gxtest-report-ref
                 gxtest-report-status
                 gxtest-report-summary
                 policy-findings
                 policy-report
                 policy-source-report
                 policy-status
                 project-policy-findings
                 project-policy-report
                 project-policy-status))

(export make-policy-test
        make-file-policy-test
        make-gxtest-policy-test
        policy-findings
        policy-status
        policy-report
        policy-source-report
        make-project-policy-test
        gxtest-report-ref
        gxtest-report-status
        gxtest-report-files
        gxtest-report-definitions
        gxtest-report-agent-repair
        gxtest-report-findings
        gxtest-report-finding-count
        gxtest-report-summary
        project-policy-findings
        project-policy-status
        project-policy-report
        display-project-policy-report)

;;; Macro boundary:
;;; - Downstream gxtest aggregators call this inside their normal test suite.
;;; - The caller passes the same entry files used by the upstream gxtest runner.
;;; - The expansion produces one ordinary files-scoped gxtest suite; dependency
;;;   and full-project policy remain explicit project gates.
;; make-gxtest-policy-test
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Expand into a gxtest policy test rooted at the supplied project root
;;       and scoped to the supplied runner entry files.
;;
;;       # Examples
;;
;;       ```scheme
;;       (test-suite "project tests"
;;         (make-gxtest-policy-test "." ["t/unit-tests.ss"])
;;         project-unit-tests)
;;       ;; => TestSuite
;;       ```
;;     %
(defsyntax (make-gxtest-policy-test stx)
  (let* ((form (syntax->datum stx))
         (root (and (pair? (cdr form)) (cadr form)))
         (files (and (pair? (cddr form)) (caddr form)))
         (resolved-files
          (cond
           ((string? files) [files])
           ((list? files) files)
           (else #f)))
         (resolved-root
          (if (string? root)
            (let* ((expanded-root
                    (path-normalize (path-expand root (current-directory))))
                   (normalized-root
                    (let trim ((end (string-length expanded-root)))
                      (if (and (> end 1)
                               (char=? (string-ref expanded-root (- end 1))
                                       #\/))
                        (trim (- end 1))
                        (substring expanded-root 0 end)))))
              (let loop ((candidate normalized-root))
                (let (parent (path-directory candidate))
                  (cond
                   ((file-exists? (path-expand "gerbil.pkg" candidate))
                    candidate)
                   ((or (not parent) (string=? parent candidate))
                    normalized-root)
                   (else (loop parent))))))
            root)))
    (cond
     ((not (and (pair? form)
                (pair? (cdr form))
                (pair? (cddr form))
                (null? (cdddr form))
                resolved-files))
      (error "bad make-gxtest-policy-test syntax"))
     (else
      (datum->syntax (stx-car stx)
                     `(gslph/src/policy/gxtest#make-policy-test
                       ,resolved-root
                       ,resolved-files))))))

;;; Boundary:
;;; - make-policy-test is the default gxtest bridge for downstream packages.
;;; - The caller supplies target files explicitly; build/test owners should pass
;;;   their internal test scope here instead of relying on process argv.
;; : (-> Root (List Path) TestSuite )
(def (make-policy-test root files)
  (test-suite "gerbil scheme scoped policy"
    (test-case "package policy passes for test scope"
      (let (report (policy-report root files))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))

;; : (-> Root Path TestSuite )
(def (make-file-policy-test root file)
  (make-policy-test root [file]))

;;; Boundary:
;;; - make-project-policy-test is the explicit full-project policy gate.
;;; - Project-level warning backlog fails through the same status contract as
;;;   check/report, so downstream packages do not need wrapper tests.
;;; - Regular gxtest targets should use make-policy-test with their file scope.
;; : (-> Root TestSuite )
(def (make-project-policy-test root)
  (test-suite "gerbil scheme project policy"
    (test-case "package policy has no findings"
      (let (report (project-policy-report root))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))

;;; -*- Gerbil -*-
;;; Tiny gxtest adapter for downstream packages that depend on this harness.

(import :parser/facade
        :policy/facade
        (only-in :std/test check test-case test-suite)
        :types/facade)

(export make-project-policy-test
        project-policy-findings)
;;; Boundary:
;;; - make-project-policy-test is the minimal gxtest bridge for package policy.
;;; - Policy ownership stays in gerbil.pkg and optional external config files.
;; TestSuite <- Root
(def (make-project-policy-test root)
  (test-suite "gerbil scheme project policy"
    (test-case "package policy passes"
      (check (type-status (project-policy-findings root)) => "pass"))))
;; (List TypeFinding) <- Root
(def (project-policy-findings root)
  (run-policy-checks (collect-project root)))

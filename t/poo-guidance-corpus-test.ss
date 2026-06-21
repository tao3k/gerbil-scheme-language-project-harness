;;; -*- Gerbil -*-
;;; POO guidance corpus snapshot test.
;;; This test runs a source-load check in a fresh gxi process so local scenario
;;; edits are not hidden by an installed package copy of t/unit/snapshot/policy.ss.

(import :std/test
        :std/misc/process)

(def +poo-guidance-corpus-check+
  "(begin (add-load-path! \"src\") (add-load-path! \"t\") (load \"t/unit/snapshot/policy.ss\") (let ((actual (poo-guidance-corpus-policy-snapshot)) (expected (call-with-input-file \"t/snapshots/policy-poo-guidance-corpus.ss\" read))) (if (equal? actual expected) (display \"ok\\n\") (begin (display \"mismatch\\n\") (pretty-print actual) (pretty-print expected) (exit 1)))))")

(export poo-guidance-corpus-test)

;; : (-> String)
(def (run-poo-guidance-corpus-check)
  (run-process ["gxi" "-e" +poo-guidance-corpus-check+]
               stderr-redirection: #t))

(def poo-guidance-corpus-test
  (test-suite "gerbil scheme harness POO guidance corpus"
    (test-case "POO guidance corpus matches local scenario facts"
      (check (run-poo-guidance-corpus-check) => "ok\n"))))

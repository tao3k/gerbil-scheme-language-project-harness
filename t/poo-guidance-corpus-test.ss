;;; -*- Gerbil -*-
;;; POO guidance corpus snapshot test.
;;; This test runs a source-load check in a fresh gxi process so local scenario
;;; edits are not hidden by an installed package copy of t/unit/snapshot/policy.ss.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-normalize)
        :std/misc/process)

(def +poo-guidance-corpus-check+
  "(begin (add-load-path! (string-append (getenv \"HOME\") \"/.gerbil/lib\")) (add-load-path! \"src\") (add-load-path! \"t\") (load \"t/unit/snapshot/policy.ss\") (let ((actual (poo-guidance-corpus-policy-snapshot)) (expected (call-with-input-file \"t/snapshots/policy-poo-guidance-corpus.ss\" read))) (if (equal? actual expected) (display \"ok\\n\") (begin (display \"mismatch\\n\") (pretty-print actual) (pretty-print expected) (exit 1)))))")

(export poo-guidance-corpus-test)

;; : (-> Path)
(def (poo-guidance-corpus-root)
  (path-normalize
   (or (getenv "PWD" #f)
       (current-directory))))

;; : (-> String)
(def (run-poo-guidance-corpus-check)
  (let (status 0)
    (let (output
          (run-process ["gxi" "-e" +poo-guidance-corpus-check+]
                       directory: (poo-guidance-corpus-root)
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status exit-status))))
      (if (zero? status)
        output
        (string-append "status=" (number->string status) "\n" output)))))

(def poo-guidance-corpus-test
  (test-suite "gerbil scheme harness POO guidance corpus"
    (test-case "POO guidance corpus matches local scenario facts"
      (check (run-poo-guidance-corpus-check) => "ok\n"))))

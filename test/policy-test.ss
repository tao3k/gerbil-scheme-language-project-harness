;;; -*- Gerbil -*-
(import :gerbil/gambit
        :std/test
        :parser
        :policy
        :types)
(export policy-test)

(def policy-test
  (test-suite "gerbil scheme harness policy"
    (test-case "modularity policy rejects facade implementation"
      (let* ((root ".run/policy-modularity")
             (_ (write-policy-project
                 root "foo"
                 ";;; -*- Gerbil -*-\n;;; Foo facade.\n(export answer)\n(def answer 42)\n"
                 ";;; -*- Gerbil -*-\n;;; Foo core.\n(def core-answer 42)\n"))
             (index (collect-project root))
             (findings (run-modularity-policy index))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-MOD-R001")
        (check (type-finding-path finding) => "src/foo.ss")))
    (test-case "agent policy requires facade intent comment"
      (let* ((root ".run/policy-agent")
             (_ (write-policy-project
                 root "bar"
                 ";;; -*- Gerbil -*-\n(export value)\n"
                 ";;; -*- Gerbil -*-\n;;; Bar core.\n(def value 1)\n"))
             (index (collect-project root))
             (findings (run-agent-policy index))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-AGENT-R001")
        (check (type-finding-path finding) => "src/bar.ss")))
    (test-case "agent policy rejects generic owner names"
      (let* ((root ".run/policy-generic-owner")
             (_ (write-policy-project
                 root "utils"
                 ";;; -*- Gerbil -*-\n;;; Utilities facade.\n(export value)\n"
                 ";;; -*- Gerbil -*-\n;;; Utilities core.\n(def value 1)\n"))
             (index (collect-project root))
             (findings (run-agent-policy index))
             (matching (filter-rule "GERBIL-SCHEME-AGENT-R002" findings))
             (finding (car matching)))
        (check (length matching) => 2)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-AGENT-R002")
        (check (type-finding-path finding) => "src/utils.ss")))
    (test-case "agent policy rejects duplicate facade exports"
      (let* ((root ".run/policy-export-conflict")
             (_alpha (write-policy-project
                      root "alpha"
                      ";;; -*- Gerbil -*-\n;;; Alpha facade.\n(export value)\n"
                      ";;; -*- Gerbil -*-\n;;; Alpha core.\n(def value 1)\n"))
             (_beta (write-policy-project
                     root "beta"
                     ";;; -*- Gerbil -*-\n;;; Beta facade.\n(export value)\n"
                     ";;; -*- Gerbil -*-\n;;; Beta core.\n(def value 2)\n"))
             (index (collect-project root))
             (findings (run-agent-policy index))
             (matching (filter-rule "GERBIL-SCHEME-AGENT-R003" findings))
             (finding (car matching)))
        (check (length matching) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-AGENT-R003")
        (check (type-finding-path finding) => "src/beta.ss")))))

(def (filter-rule rule-id findings)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding) rule-id))
          findings))

(def (write-policy-project root facade-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" facade-name))
         (facade-path (string-append src "/" facade-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))

(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))

(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))

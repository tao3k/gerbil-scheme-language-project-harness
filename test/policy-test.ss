;;; -*- Gerbil -*-
(import :gerbil/gambit
        :std/test
        :parser/facade
        :policy/facade
        :types/facade)
(export policy-test)

(def policy-test
  (test-suite "gerbil scheme harness policy"
    (test-case "modularity policy rejects facade implementation"
      (let* ((root ".run/policy-modularity")
             (_ (write-facade-policy-project
                 root "foo"
                 ";;; -*- Gerbil -*-\n;;; Foo facade.\n(export answer)\n(def answer 42)\n"
                 ";;; -*- Gerbil -*-\n;;; Foo core.\n(def core-answer 42)\n"))
             (index (collect-project root))
             (findings (run-modularity-policy index))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-MOD-R001")
        (check (type-finding-path finding) => "src/foo/facade.ss")))
    (test-case "modularity policy rejects sibling file and owner directory"
      (let* ((root ".run/policy-owner-collision")
             (_ (write-policy-project
                 root "foo"
                 ";;; -*- Gerbil -*-\n;;; Foo sibling entry.\n(export answer)\n"
                 ";;; -*- Gerbil -*-\n;;; Foo core.\n(def core-answer 42)\n"))
             (index (collect-project root))
             (findings (run-modularity-policy index))
             (matching (filter-rule "GERBIL-SCHEME-MOD-R003" findings))
             (finding (car matching)))
        (check (length matching) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-MOD-R003")
        (check (type-finding-path finding) => "src/foo.ss")))
    (test-case "modularity policy rejects repeated owner entry names"
      (let* ((root ".run/policy-repeated-owner-entry")
             (_ (write-owner-entry-policy-project
                 root "foo"
                 ";;; -*- Gerbil -*-\n;;; Foo repeated entry.\n(export answer)\n"
                 ";;; -*- Gerbil -*-\n;;; Foo core.\n(def core-answer 42)\n"))
             (index (collect-project root))
             (findings (run-modularity-policy index))
             (matching (filter-rule "GERBIL-SCHEME-MOD-R004" findings))
             (finding (car matching)))
        (check (length matching) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-MOD-R004")
        (check (type-finding-path finding) => "src/foo/foo.ss")))
    (test-case "agent policy requires facade intent comment"
      (let* ((root ".run/policy-agent")
             (_ (write-facade-policy-project
                 root "bar"
                 ";;; -*- Gerbil -*-\n(export value)\n"
                 ";;; -*- Gerbil -*-\n;;; Bar core.\n(def value 1)\n"))
             (index (collect-project root))
             (findings (run-agent-policy index))
             (finding (car findings)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-AGENT-R001")
        (check (type-finding-path finding) => "src/bar/facade.ss")))
    (test-case "modularity policy rejects oversized source leaves"
      (let* ((root ".run/policy-source-leaf")
             (_ (write-large-policy-source root "large"))
             (index (collect-project root))
             (findings (run-modularity-policy index))
             (matching (filter-rule "GERBIL-SCHEME-MOD-R002" findings))
             (finding (car matching)))
        (check (length matching) => 1)
        (check (type-finding-rule-id finding)
               => "GERBIL-SCHEME-MOD-R002")
        (check (type-finding-path finding) => "src/large/core.ss")))
    (test-case "agent policy rejects generic owner names"
      (let* ((root ".run/policy-generic-owner")
             (_ (write-facade-policy-project
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
        (check (not (not (member "src/utils/facade.ss"
                                  (map type-finding-path matching))))
               => #t)))
    (test-case "agent policy rejects duplicate facade exports"
      (let* ((root ".run/policy-export-conflict")
             (_alpha (write-facade-policy-project
                      root "alpha"
                      ";;; -*- Gerbil -*-\n;;; Alpha facade.\n(export value)\n"
                      ";;; -*- Gerbil -*-\n;;; Alpha core.\n(def value 1)\n"))
             (_beta (write-facade-policy-project
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
        (check (type-finding-path finding) => "src/beta/facade.ss")))))

(def (filter-rule rule-id findings)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding) rule-id))
          findings))

(def (write-policy-project root facade-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" facade-name))
         (facade-path (string-append src "/" facade-name ".ss"))
         (owner-entry-path (string-append owner "/" facade-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists owner-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))

(def (write-owner-entry-policy-project root owner-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (sibling-path (string-append src "/" owner-name ".ss"))
         (facade-entry-path (string-append owner "/facade.ss"))
         (facade-path (string-append owner "/" owner-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists sibling-path)
    (delete-file-if-exists facade-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))

(def (write-facade-policy-project root owner-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (sibling-path (string-append src "/" owner-name ".ss"))
         (repeated-entry-path (string-append owner "/" owner-name ".ss"))
         (facade-path (string-append owner "/facade.ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists sibling-path)
    (delete-file-if-exists repeated-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))

(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))

(def (write-text path text)
  (delete-file-if-exists path)
  (call-with-output-file path
    (lambda (port) (display text port))))

(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))

(def (write-large-policy-source root owner-name)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (source-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n;;; Large source leaf.\n" port)
        (let lp ((index 0))
          (when (fx< index 45)
            (display "(def value" port)
            (display index port)
            (display " " port)
            (display index port)
            (display ")\n" port)
            (lp (fx1+ index))))
        (let lp ((index 0))
          (when (fx< index 610)
            (display ";; padding\n" port)
            (lp (fx1+ index))))))))

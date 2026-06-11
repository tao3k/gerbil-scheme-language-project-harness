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
        (check (type-finding-path finding) => "src/bar.ss")))))

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

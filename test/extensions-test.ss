;;; -*- Gerbil -*-
(import :extensions/facade
        :parser/facade
        :snapshot/facade
        :std/test)
(export extensions-test)

(def extensions-test
  (test-suite "gerbil scheme harness extensions"
    (test-case "poo extension packet matches snapshot"
      (let* ((root ".run/extensions-poo-required")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (snapshot (extension-packet-snapshot index))
             (expected (snapshot-load "test/snapshots/poo-extension-packet.ss")))
        (check snapshot => expected)))
    (test-case "poo search prime snapshot matches packet interface"
      (let* ((root ".run/extensions-poo-search-prime")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (snapshot (search-prime-snapshot index))
             (expected (snapshot-load "test/snapshots/poo-search-prime-packet.ss")))
        (check snapshot => expected)))
    (test-case "poo dependency aliases activate extension"
      (let* ((root ".run/extensions-poo-alias")
             (_ (write-extension-project root "sample/app" ["clan/poo"]))
             (index (collect-project root))
             (extension (car (project-extension-json index))))
        (check (poo-extension-active? index) => #t)
        (check (hash-get extension 'name) => "poo")
        (check (hash-get extension 'dependencyMode) => "required")
        (check (hash-get extension 'dependencies) => ["clan/poo"])))
    (test-case "poo extension does not activate from package name alone"
      (let* ((root ".run/extensions-poo-package-name-only")
             (_ (write-extension-project
                 root
                 "clan/poo"
                 ["git.cons.io/mighty-gerbils/gerbil-utils"]))
             (index (collect-project root)))
        (check (poo-extension-active? index) => #f)
        (check (project-extension-json index) => '())
        (check (project-extension-search-lines index) => '())))
    (test-case "poo extension rejects similar dependency names"
      (let* ((root ".run/extensions-poo-negative")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poof"]))
             (index (collect-project root)))
        (check (poo-extension-active? index) => #f)
        (check (project-extension-json index) => '())
        (check (project-extension-search-lines index) => '())))))

(def (write-extension-project root package-name dependencies)
  (let* ((src (string-append root "/src"))
         (package-path (string-append root "/gerbil.pkg"))
         (source-path (string-append src "/main.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (write-text package-path
                (string-append
                 "(package: "
                 package-name
                 "\n depend: "
                 (dependency-list-source dependencies)
                 ")\n"))
    (write-text source-path
                (string-append "(package: " package-name "/main)\n(def answer 42)\n"))))

(def (dependency-list-source dependencies)
  (string-append "(" (quoted-string-list-source dependencies) ")"))

(def (quoted-string-list-source dependencies)
  (match dependencies
    ([] "")
    ([dependency] (string-append "\"" dependency "\""))
    ([dependency . more]
     (string-append "\"" dependency "\" "
                    (quoted-string-list-source more)))))

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

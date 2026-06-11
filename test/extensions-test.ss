;;; -*- Gerbil -*-
(import :extensions/facade
        :parser/facade
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
             (expected (load-snapshot "test/snapshots/poo-extension-packet.scm")))
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

(def (extension-packet-snapshot index)
  (list (package-snapshot (project-index-package index))
        (list 'extensions
              (map extension-json-snapshot (project-extension-json index)))
        (list 'search-lines (project-extension-search-lines index))))

(def (package-snapshot package)
  (list 'package
        (project-package-name package)
        (project-package-path package)
        (project-package-manager package)
        (project-package-dependencies package)))

(def (extension-json-snapshot extension)
  [(hash-get extension 'name)
   (hash-get extension 'activation)
   (hash-get extension 'dependencyMode)
   (hash-get extension 'packageManager)
   (hash-get extension 'package)
   (hash-get extension 'dependencies)
   (hash-get extension 'capabilities)])

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

(def (load-snapshot path)
  (call-with-input-file path read))

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

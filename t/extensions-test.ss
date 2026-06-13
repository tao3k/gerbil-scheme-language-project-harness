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
             (expected (snapshot-load "t/snapshots/poo-extension-packet.ss")))
        (check snapshot => expected)))
    (test-case "poo search prime snapshot matches packet interface"
      (let* ((root ".run/extensions-poo-search-prime")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (snapshot (search-prime-snapshot index))
             (expected (snapshot-load "t/snapshots/poo-search-prime-packet.ss")))
        (check snapshot => expected)))
    (test-case "poo dependency aliases activate extension"
      (let* ((root ".run/extensions-poo-alias")
             (_ (write-extension-project root "sample/app" ["clan/poo"]))
             (index (collect-project root))
             (extension (car (project-extension-json index)))
             (source-ref (poo-source-ref index)))
        (check (poo-extension-active? index) => #t)
        (check (hash-get extension 'name) => "poo")
        (check (hash-get extension 'dependencyMode) => "required")
        (check (hash-get extension 'dependencies) => ["clan/poo"])
        (check (hash-get source-ref 'kind) => "package-manager-download")
        (check (hash-get source-ref 'manager) => "gxpkg")
        (check (hash-get source-ref 'dependency) => "clan/poo")
        (check (hash-get source-ref 'pathPolicy) => "runtime-resolved")))
    (test-case "poo scenario preserves mixed dependency context"
      (let* ((root ".run/extensions-poo-mixed-deps")
             (dependencies ["github.com/acme/logging"
                            "git.cons.io/mighty-gerbils/gerbil-poo"
                            "github.com/acme/metrics"])
             (_ (write-extension-project root "sample/app" dependencies))
             (index (collect-project root))
             (extension (car (project-extension-json index))))
        (check (poo-extension-active? index) => #t)
        (check (hash-get extension 'package) => "sample/app")
        (check (hash-get extension 'dependencies) => dependencies)
        (check (hash-get extension 'capabilities)
               => ["object-system" "metaobject-protocol" "protocols"])))
    (test-case "poo pattern evidence is downstream extension guidance"
      (let* ((root ".run/extensions-poo-pattern-evidence")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["poo" "class" "method" "protocol"]))
             (source-ref (hash-get pattern 'sourceRef))
             (selectors (hash-get pattern 'selectors))
             (first-selector (car selectors)))
        (check (hash-get pattern 'agentScenario)
               => "agent-does-not-know-gerbil-poo-object-system")
        (check (hash-get pattern 'intent)
               => "write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing")
        (check (hash-get source-ref 'kind) => "package-manager-download")
        (check (hash-get source-ref 'dependency)
               => "git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get source-ref 'pathPolicy) => "runtime-resolved")
        (check (not (not (member "proto.ss"
                                  (hash-get pattern 'sourceOwners))))
               => #t)
        (check (hash-get first-selector 'selector)
               => "gerbil-poo://object.ss#defclass")
        (check (length (hash-get pattern 'selectors)) => 7)
        (check (length (hash-get pattern 'minimalForms)) => 6)
        (check (length (hash-get pattern 'failureCases)) => 4)
        (check (not (not (member "dependency-backed-mapping"
                                  (hash-get pattern 'qualitySignals))))
               => #t)))
    (test-case "poo pattern evidence requires activated dependency"
      (let* ((root ".run/extensions-poo-pattern-inactive")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-utils"]))
             (index (collect-project root)))
        (check (poo-pattern-evidence index ["poo" "class"]) => #f)))
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

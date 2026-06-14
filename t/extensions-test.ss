;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :extensions/facade
        :parser/facade
        :snapshot/facade
        :std/test)
(export extensions-test)
;; ExtensionsTest
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
               => ["object-system"
                   "metaobject-protocol"
                   "protocols"
                   "policy-protocol"
                   "macro-governance"
                   "user-override-witness"
                   "inherited-gerbil-utils"
                   "higher-order-control"
                   "typed-combinator-style"
                   "pattern-inheritance"])))
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
    (test-case "poo pattern evidence inherits gerbil-utils combinator guidance"
      (let* ((root ".run/extensions-poo-inherited-utils-pattern")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["higher-order-control" "gerbil-utils" "inherited"]))
             (source-ref (hash-get pattern 'sourceRef))
             (import-witness (hash-get pattern 'importWitness))
             (selectors (hash-get pattern 'selectors)))
        (check (hash-get pattern 'id) => "gerbil-utils-higher-order-control")
        (check (hash-get pattern 'origin) => "inherited")
        (check (hash-get pattern 'via)
               => ["git.cons.io/mighty-gerbils/gerbil-poo"
                   "git.cons.io/mighty-gerbils/gerbil-utils"])
        (check (hash-get source-ref 'dependency)
               => "git.cons.io/mighty-gerbils/gerbil-utils")
        (check (hash-get import-witness 'module) => ":clan/base")
        (check (hash-get import-witness 'status) => "verified")
        (check (hash-get (car selectors) 'selector)
               => "gerbil-utils://base.ss#rcompose")
        (check (not (not (member "package-closure-inheritance"
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
    (test-case "gerbil-poo usage query uses logical selector registry"
      (let* ((root ".run/extensions-poo-registered-query")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-utils"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["gerbil-poo" "usage"]))
             (source-ref (hash-get pattern 'sourceRef))
             (signals (hash-get pattern 'qualitySignals))
             (selectors (hash-get pattern 'selectors)))
        (check (poo-extension-active? index) => #f)
        (check (project-extension-json index) => '())
        (check (hash-get pattern 'id) => "poo-object-system")
        (check (hash-get pattern 'origin) => "registered")
        (check (hash-get source-ref 'selectorScheme)
               => "gerbil-poo-logical-symbol")
        (check (not (not (member "gerbil-poo-logical-selector-registry"
                                  signals)))
               => #t)
        (check (not (not (member "active-extension-fact" signals)))
               => #f)
        (check (hash-get (car selectors) 'selector)
               => "gerbil-poo://object.ss#defclass")))
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
;; Unit <- String PackageName (List XX)
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
;; DependencyListSource <- (List DependencyName)
(def (dependency-list-source dependencies)
  (string-append "(" (quoted-string-list-source dependencies) ")"))
;; QuotedStringListSource <- (List DependencyName)
(def (quoted-string-list-source dependencies)
  (match dependencies
    ([] "")
    ([dependency] (string-append "\"" dependency "\""))
    ([dependency . more]
     (string-append "\"" dependency "\" "
                    (quoted-string-list-source more)))))
;; EnsureDir <- String
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; Unit <- String SourceLine
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))

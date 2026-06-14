;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :extensions/facade
        :parser/facade
        :snapshot/facade
        :std/sugar
        :std/test)
(export check-extension-snapshot-schema-fields
        check-extension-search-snapshot-schema-fields
        check-pattern-search-snapshot-quality-fields
        check-pattern-search-snapshot-c3-mro-fields
        check-pattern-search-snapshot-partial-missing-fields
        check-pattern-search-snapshot-fixtures
        check-pattern-search-snapshot-source-gap-fixtures)
;; Fact
(def (sample-poo-extension-fact)
  (make-extension-fact "poo"
                       "gerbil.pkg"
                       "required"
                       "gxpkg"
                       "sample/app"
                       ["git.cons.io/mighty-gerbils/gerbil-poo"]
                       ["object-system"
                        "metaobject-protocol"
                        "protocols"
                        "policy-protocol"
                        "macro-governance"
                        "user-override-witness"]))
;; SamplePooC3Pattern
(def (sample-poo-c3-pattern)
  (hash (id "poo-c3-mro-regression")
        (extension "poo")
        (focus "c3 mro slot order")
        (sourceRef (hash (kind "package-manager-download")
                         (manager "gxpkg")
                         (package "poo")
                         (dependency "git.cons.io/mighty-gerbils/gerbil-poo")
                         (repository "git.cons.io/mighty-gerbils/gerbil-poo")
                         (pathPolicy "runtime-resolved")
                         (selectorScheme "gerbil-poo-logical-symbol")))
        (sourceOwners ["object.ss"
                       "mop.ss"
                       "proto.ss"
                       ":gerbil/runtime/c3"
                       "src/gerbil/test/c3-test.ss"])
        (agentScenario "agent-writes-poo-inheritance-without-knowing-c3-linearization")
        (intent "force-agent-to-query-poo-and-runtime-c3-witnesses-before-editing-inheritance")
        (selectors
         [(hash (role "class-definition")
                (symbol "defclass")
                (selector "gerbil-poo://object.ss#defclass"))
          (hash (role "method-resolution-order")
                (symbol "class-precedence-list")
                (selector "gerbil-runtime://c3.ss#class-precedence-list"))
          (hash (role "real-project-semantic-test")
                (symbol "c3-test")
                (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"))])
        (minimalForms
         [(hash (role "class-definition")
                (symbol "defclass")
                (template (hash (head "defclass")
                                (operands ["(<Class> <Base>)" "(<slot> ...)"])
                                (keywords ["transparent: #t"])))
                (selector "gerbil-poo://object.ss#defclass"))
          (hash (role "mro-regression-test")
                (symbol "class-precedence-list")
                (template (hash (head "check")
                                (operands ["(map ##type-name (class-precedence-list <Class>::t))"
                                           "'(<Class> <Base> ... object t)"])
                                (keywords [])))
                (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance"))
          (hash (role "slot-order-regression-test")
                (symbol "class-type-slot-vector")
                (template (hash (head "check")
                                (operands ["(class-type-slot-vector <Class>::t)"
                                           "#(__class <base-slots> ... <class-slots> ...)"])
                                (keywords [])))
                (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order"))])
        (failureCases
         [(hash (id "unchecked-mro-assumption")
                (riskKind "semantic-regression-gap")
                (correctiveAction "add-c3-linearization-and-slot-vector-witnesses")
                (badPattern "class-hierarchy-without-c3-or-slot-order-test")
                (selectors ["gerbil-runtime://c3.ss#class-precedence-list"
                            "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
                            "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order"]))
          (hash (id "method-without-generic")
                (riskKind "incomplete-method-contract")
                (correctiveAction "follow-generic-and-method-mappings-together")
                (badPattern "defmethod-without-generic-slot-contract")
                (selectors ["gerbil-poo://mop.ss#.defgeneric"
                            "gerbil-poo://mop.ss#defmethod"]))])
        (qualitySignals ["active-extension-fact"
                         "dependency-backed-mapping"
                         "real-project-c3-test"
                         "mro-linearization-witness"
                         "slot-order-witness"
                         "failure-cases"])
        (witness "real-project-c3-and-slot-order-witness")))
;; Snapshot
(def (check-extension-snapshot-schema-fields)
  (let (fact (sample-poo-extension-fact))
    (check (extension-fact-snapshot fact)
           => '(providerExtension
                (name "poo")
                (activation "gerbil.pkg")
                (dependencyMode "required")
                (packageManager "gxpkg")
                (package "sample/app")
                (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
                (capabilities ("object-system" "metaobject-protocol" "protocols" "policy-protocol" "macro-governance" "user-override-witness"))))))
;; Snapshot
(def (check-extension-search-snapshot-schema-fields)
  (let (fact (sample-poo-extension-fact))
    (check (extension-search-snapshot "poo syntax"
                                      [fact]
                                      "search pattern poo syntax")
           => '(extensionSearch
                (namespace "extension")
                (authority "ecosystem-extension")
                (evidenceGrade "fact")
                (query "poo syntax")
                (matches
                 ((providerExtension
                   (name "poo")
                   (activation "gerbil.pkg")
                   (dependencyMode "required")
                   (packageManager "gxpkg")
                   (package "sample/app")
                   (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
                   (capabilities ("object-system" "metaobject-protocol" "protocols" "policy-protocol" "macro-governance" "user-override-witness")))))
                (next "search pattern poo syntax")))))
;; Snapshot
(def (check-pattern-search-snapshot-quality-fields)
  (let (pattern (hash (id "poo-object-system")
                      (extension "poo")
                      (focus "object-system")
                      (sourceRef (hash (kind "package-manager-download")
                                       (manager "gxpkg")
                                       (package "poo")
                                       (dependency "git.cons.io/mighty-gerbils/gerbil-poo")
                                       (repository "git.cons.io/mighty-gerbils/gerbil-poo")
                                       (pathPolicy "runtime-resolved")
                                       (selectorScheme "gerbil-poo-logical-symbol")))
                      (sourceOwners ["object.ss" "mop.ss" "proto.ss"])
                      (selectors
                       [(hash (role "class-definition")
                              (symbol "defclass")
                              (selector "gerbil-poo://object.ss#defclass"))
                        (hash (role "generic-definition")
                              (symbol ".defgeneric")
                              (selector "gerbil-poo://mop.ss#.defgeneric"))
                        (hash (role "method-dispatch")
                              (symbol "defmethod")
                              (selector "gerbil-poo://mop.ss#defmethod"))
                        (hash (role "protocol-composition")
                              (symbol "proto")
                              (selector "gerbil-poo://mop.ss#proto"))
                        (hash (role "prototype-composition")
                              (symbol "compose-proto")
                              (selector "gerbil-poo://proto.ss#compose-proto"))])
                      (agentScenario "agent-does-not-know-gerbil-poo-object-system")
                      (intent "write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing")
                      (minimalForms
                       [(hash (role "class-definition")
                              (symbol "defclass")
                              (template (hash (head "defclass")
                                              (operands ["(<Class> <Base>)" "(<slot> ...)"])
                                              (keywords ["transparent: #t"])))
                              (selector "gerbil-poo://object.ss#defclass"))
                        (hash (role "method-dispatch")
                              (symbol "defmethod")
                              (template (hash (head "defmethod")
                                              (operands ["(@@method <generic> <type>)"
                                                         "(lambda (self) ...)"])
                                              (keywords [])))
                              (selector "gerbil-poo://mop.ss#defmethod"))
                        (hash (role "generic-definition")
                              (symbol ".defgeneric")
                              (template (hash (head ".defgeneric")
                                              (operands ["(<generic> <type> <arg>)"])
                                              (keywords ["slot: .<slot>"])))
                              (selector "gerbil-poo://mop.ss#.defgeneric"))
                        (hash (role "protocol-composition")
                              (symbol "compose-proto")
                              (template (hash (head "compose-proto")
                                              (operands ["<proto-a>" "<proto-b>"])
                                              (keywords [])))
                              (selector "gerbil-poo://proto.ss#compose-proto"))])
                      (failureCases
                       [(hash (id "racket-class-syntax")
                              (riskKind "dialect-confusion")
                              (correctiveAction "use-poo-form-mapping")
                              (badPattern "racket-class-or-generic-scheme-object")
                              (selectors ["gerbil-poo://object.ss#defclass"
                                          "gerbil-poo://mop.ss#.defgeneric"
                                          "gerbil-poo://mop.ss#defmethod"]))
                        (hash (id "missing-extension-activation")
                              (riskKind "inactive-extension")
                              (correctiveAction "query-extension-before-pattern")
                              (badPattern "poo-forms-without-gerbil.pkg-dependency")
                              (selectors ["gerbil.pkg"]))
                        (hash (id "method-without-generic")
                              (riskKind "incomplete-method-contract")
                              (correctiveAction "follow-generic-and-method-mappings-together")
                              (badPattern "defmethod-without-generic-slot-contract")
                              (selectors ["gerbil-poo://mop.ss#.defgeneric"
                                          "gerbil-poo://mop.ss#defmethod"]))])
                      (qualitySignals ["active-extension-fact"
                                       "dependency-backed-mapping"
                                       "minimal-forms"
                                       "failure-cases"])
                      (witness "dependency-backed-poo-mapping")))
    (check (pattern-search-snapshot "poo syntax"
                                    pattern
                                    []
                                    "search extension poo syntax")
           => '(patternSearch
                (namespace "pattern")
                (authority "executable-pattern")
                (evidenceGrade "fact")
                (quality "verified")
                (query "poo syntax")
                (pattern
                 (pattern
                  (id "poo-object-system")
                  (extension "poo")
                  (focus "object-system")
                  (sourceRef
                   (kind "package-manager-download")
                   (manager "gxpkg")
                   (package "poo")
                   (dependency "git.cons.io/mighty-gerbils/gerbil-poo")
                   (repository "git.cons.io/mighty-gerbils/gerbil-poo")
                   (pathPolicy "runtime-resolved")
                   (selectorScheme "gerbil-poo-logical-symbol"))
                  (sourceOwners ("object.ss" "mop.ss" "proto.ss"))
                  (agentScenario "agent-does-not-know-gerbil-poo-object-system")
                  (intent "write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing")
                  (selectors
                   ((selector
                     (role "class-definition")
                     (symbol "defclass")
                     (selector "gerbil-poo://object.ss#defclass"))
                    (selector
                     (role "generic-definition")
                     (symbol ".defgeneric")
                     (selector "gerbil-poo://mop.ss#.defgeneric"))
                    (selector
                     (role "method-dispatch")
                     (symbol "defmethod")
                     (selector "gerbil-poo://mop.ss#defmethod"))
                    (selector
                     (role "protocol-composition")
                     (symbol "proto")
                     (selector "gerbil-poo://mop.ss#proto"))
                    (selector
                     (role "prototype-composition")
                     (symbol "compose-proto")
                     (selector "gerbil-poo://proto.ss#compose-proto"))))
                  (minimalForms
                   ((form
                     (role "class-definition")
                     (symbol "defclass")
                     (template
                      (head "defclass")
                      (operands ("(<Class> <Base>)" "(<slot> ...)"))
                      (keywords ("transparent: #t")))
                     (selector "gerbil-poo://object.ss#defclass"))
                    (form
                     (role "method-dispatch")
                     (symbol "defmethod")
                     (template
                      (head "defmethod")
                      (operands ("(@@method <generic> <type>)" "(lambda (self) ...)"))
                      (keywords ()))
                     (selector "gerbil-poo://mop.ss#defmethod"))
                    (form
                     (role "generic-definition")
                     (symbol ".defgeneric")
                     (template
                      (head ".defgeneric")
                      (operands ("(<generic> <type> <arg>)"))
                      (keywords ("slot: .<slot>")))
                     (selector "gerbil-poo://mop.ss#.defgeneric"))
                    (form
                     (role "protocol-composition")
                     (symbol "compose-proto")
                     (template
                      (head "compose-proto")
                      (operands ("<proto-a>" "<proto-b>"))
                      (keywords ()))
                     (selector "gerbil-poo://proto.ss#compose-proto"))))
                  (failureCases
                   ((failureCase
                     (id "racket-class-syntax")
                     (riskKind "dialect-confusion")
                     (correctiveAction "use-poo-form-mapping")
                     (badPattern "racket-class-or-generic-scheme-object")
                     (selectors ("gerbil-poo://object.ss#defclass"
                                 "gerbil-poo://mop.ss#.defgeneric"
                                 "gerbil-poo://mop.ss#defmethod")))
                    (failureCase
                     (id "missing-extension-activation")
                     (riskKind "inactive-extension")
                     (correctiveAction "query-extension-before-pattern")
                     (badPattern "poo-forms-without-gerbil.pkg-dependency")
                     (selectors ("gerbil.pkg")))
                    (failureCase
                     (id "method-without-generic")
                     (riskKind "incomplete-method-contract")
                     (correctiveAction "follow-generic-and-method-mappings-together")
                     (badPattern "defmethod-without-generic-slot-contract")
                     (selectors ("gerbil-poo://mop.ss#.defgeneric"
                                 "gerbil-poo://mop.ss#defmethod")))))
                  (qualitySignals ("active-extension-fact"
                                   "dependency-backed-mapping"
                                   "minimal-forms"
                                   "failure-cases"))
                  (witness "dependency-backed-poo-mapping")))
                (missing ())
                (witness "dependency-backed-poo-mapping")
                (next "search extension poo syntax")))))
;; Snapshot
(def (check-pattern-search-snapshot-c3-mro-fields)
  (let (pattern (sample-poo-c3-pattern))
    (check (pattern-search-snapshot "poo c3 mro slot order"
                                    pattern
                                    []
                                    "search extension poo pattern c3")
           => '(patternSearch
                (namespace "pattern")
                (authority "executable-pattern")
                (evidenceGrade "fact")
                (quality "verified")
                (query "poo c3 mro slot order")
                (pattern
                 (pattern
                  (id "poo-c3-mro-regression")
                  (extension "poo")
                  (focus "c3 mro slot order")
                  (sourceRef
                   (kind "package-manager-download")
                   (manager "gxpkg")
                   (package "poo")
                   (dependency "git.cons.io/mighty-gerbils/gerbil-poo")
                   (repository "git.cons.io/mighty-gerbils/gerbil-poo")
                   (pathPolicy "runtime-resolved")
                   (selectorScheme "gerbil-poo-logical-symbol"))
                  (sourceOwners ("object.ss"
                                 "mop.ss"
                                 "proto.ss"
                                 ":gerbil/runtime/c3"
                                 "src/gerbil/test/c3-test.ss"))
                  (agentScenario "agent-writes-poo-inheritance-without-knowing-c3-linearization")
                  (intent "force-agent-to-query-poo-and-runtime-c3-witnesses-before-editing-inheritance")
                  (selectors
                   ((selector
                     (role "class-definition")
                     (symbol "defclass")
                     (selector "gerbil-poo://object.ss#defclass"))
                    (selector
                     (role "method-resolution-order")
                     (symbol "class-precedence-list")
                     (selector "gerbil-runtime://c3.ss#class-precedence-list"))
                    (selector
                     (role "real-project-semantic-test")
                     (symbol "c3-test")
                     (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"))))
                  (minimalForms
                   ((form
                     (role "class-definition")
                     (symbol "defclass")
                     (template
                      (head "defclass")
                      (operands ("(<Class> <Base>)" "(<slot> ...)"))
                      (keywords ("transparent: #t")))
                     (selector "gerbil-poo://object.ss#defclass"))
                    (form
                     (role "mro-regression-test")
                     (symbol "class-precedence-list")
                     (template
                      (head "check")
                      (operands ("(map ##type-name (class-precedence-list <Class>::t))"
                                 "'(<Class> <Base> ... object t)"))
                      (keywords ()))
                     (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance"))
                    (form
                     (role "slot-order-regression-test")
                     (symbol "class-type-slot-vector")
                     (template
                      (head "check")
                      (operands ("(class-type-slot-vector <Class>::t)"
                                 "#(__class <base-slots> ... <class-slots> ...)"))
                      (keywords ()))
                     (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order"))))
                  (failureCases
                   ((failureCase
                     (id "unchecked-mro-assumption")
                     (riskKind "semantic-regression-gap")
                     (correctiveAction "add-c3-linearization-and-slot-vector-witnesses")
                     (badPattern "class-hierarchy-without-c3-or-slot-order-test")
                     (selectors ("gerbil-runtime://c3.ss#class-precedence-list"
                                 "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
                                 "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order")))
                    (failureCase
                     (id "method-without-generic")
                     (riskKind "incomplete-method-contract")
                     (correctiveAction "follow-generic-and-method-mappings-together")
                     (badPattern "defmethod-without-generic-slot-contract")
                     (selectors ("gerbil-poo://mop.ss#.defgeneric"
                                 "gerbil-poo://mop.ss#defmethod")))))
                  (qualitySignals ("active-extension-fact"
                                   "dependency-backed-mapping"
                                   "real-project-c3-test"
                                   "mro-linearization-witness"
                                   "slot-order-witness"
                                   "failure-cases"))
                  (witness "real-project-c3-and-slot-order-witness")))
                (missing ())
                (witness "real-project-c3-and-slot-order-witness")
                (next "search extension poo pattern c3")))))
;; Snapshot
(def (check-pattern-search-snapshot-partial-missing-fields)
  (let (pattern (sample-poo-c3-pattern))
    (check (pattern-search-snapshot "poo c3 without runtime test index"
                                    pattern
                                    ["runtime-c3-test-index"
                                     "slot-order-witness-refresh"]
                                    "search runtime-source c3-test")
           => '(patternSearch
                (namespace "pattern")
                (authority "executable-pattern")
                (evidenceGrade "fact")
                (quality "partial")
                (query "poo c3 without runtime test index")
                (pattern
                 (pattern
                  (id "poo-c3-mro-regression")
                  (extension "poo")
                  (focus "c3 mro slot order")
                  (sourceRef
                   (kind "package-manager-download")
                   (manager "gxpkg")
                   (package "poo")
                   (dependency "git.cons.io/mighty-gerbils/gerbil-poo")
                   (repository "git.cons.io/mighty-gerbils/gerbil-poo")
                   (pathPolicy "runtime-resolved")
                   (selectorScheme "gerbil-poo-logical-symbol"))
                  (sourceOwners ("object.ss"
                                 "mop.ss"
                                 "proto.ss"
                                 ":gerbil/runtime/c3"
                                 "src/gerbil/test/c3-test.ss"))
                  (agentScenario "agent-writes-poo-inheritance-without-knowing-c3-linearization")
                  (intent "force-agent-to-query-poo-and-runtime-c3-witnesses-before-editing-inheritance")
                  (selectors
                   ((selector
                     (role "class-definition")
                     (symbol "defclass")
                     (selector "gerbil-poo://object.ss#defclass"))
                    (selector
                     (role "method-resolution-order")
                     (symbol "class-precedence-list")
                     (selector "gerbil-runtime://c3.ss#class-precedence-list"))
                    (selector
                     (role "real-project-semantic-test")
                     (symbol "c3-test")
                     (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"))))
                  (minimalForms
                   ((form
                     (role "class-definition")
                     (symbol "defclass")
                     (template
                      (head "defclass")
                      (operands ("(<Class> <Base>)" "(<slot> ...)"))
                      (keywords ("transparent: #t")))
                     (selector "gerbil-poo://object.ss#defclass"))
                    (form
                     (role "mro-regression-test")
                     (symbol "class-precedence-list")
                     (template
                      (head "check")
                      (operands ("(map ##type-name (class-precedence-list <Class>::t))"
                                 "'(<Class> <Base> ... object t)"))
                      (keywords ()))
                     (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance"))
                    (form
                     (role "slot-order-regression-test")
                     (symbol "class-type-slot-vector")
                     (template
                      (head "check")
                      (operands ("(class-type-slot-vector <Class>::t)"
                                 "#(__class <base-slots> ... <class-slots> ...)"))
                      (keywords ()))
                     (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order"))))
                  (failureCases
                   ((failureCase
                     (id "unchecked-mro-assumption")
                     (riskKind "semantic-regression-gap")
                     (correctiveAction "add-c3-linearization-and-slot-vector-witnesses")
                     (badPattern "class-hierarchy-without-c3-or-slot-order-test")
                     (selectors ("gerbil-runtime://c3.ss#class-precedence-list"
                                 "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
                                 "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order")))
                    (failureCase
                     (id "method-without-generic")
                     (riskKind "incomplete-method-contract")
                     (correctiveAction "follow-generic-and-method-mappings-together")
                     (badPattern "defmethod-without-generic-slot-contract")
                     (selectors ("gerbil-poo://mop.ss#.defgeneric"
                                 "gerbil-poo://mop.ss#defmethod")))))
                  (qualitySignals ("active-extension-fact"
                                   "dependency-backed-mapping"
                                   "real-project-c3-test"
                                   "mro-linearization-witness"
                                   "slot-order-witness"
                                   "failure-cases"))
                  (witness "real-project-c3-and-slot-order-witness")))
                (missing ("runtime-c3-test-index"
                          "slot-order-witness-refresh"))
                (witness "real-project-c3-and-slot-order-witness")
                (next "search runtime-source c3-test")))))
;; Snapshot
(def (check-pattern-search-snapshot-fixtures)
  (let (pattern (sample-poo-c3-pattern))
    (check (pattern-search-snapshot "poo c3 mro slot order"
                                    pattern
                                    []
                                    "search extension poo pattern c3")
           => (snapshot-load "t/snapshots/poo-c3-mro-pattern.ss"))
    (check (pattern-search-snapshot "poo c3 without runtime test index"
                                    pattern
                                    ["runtime-c3-test-index"
                                     "slot-order-witness-refresh"]
                                    "search runtime-source c3-test")
           => (snapshot-load "t/snapshots/poo-c3-mro-partial.ss"))))
;; Snapshot
(def (check-pattern-search-snapshot-source-gap-fixtures)
  (let* ((index (collect-project "."))
         (prototype (poo-pattern-evidence index ["poo" "prototype" "compose-proto"]))
         (trace-debug (poo-pattern-evidence index ["poo" "trace" "debug"]))
         (slot-cache (poo-pattern-evidence index ["poo" "slot" "cache" "computed"]))
         (io-json (poo-pattern-evidence index ["poo" "json" "fallback"]))
         (lens (poo-pattern-evidence index ["poo" "lens" "slot-lens"]))
         (type-validation (poo-pattern-evidence index ["poo" "sealed" "validate"])))
    (check (pattern-search-snapshot "poo prototype compose-proto"
                                    prototype
                                    (hash-get prototype 'missing)
                                    (hash-get prototype 'next))
           => (snapshot-load "t/snapshots/poo-prototype-composition-pattern.ss"))
    (check (pattern-search-snapshot "poo trace debug"
                                    trace-debug
                                    (hash-get trace-debug 'missing)
                                    (hash-get trace-debug 'next))
           => (snapshot-load "t/snapshots/poo-trace-debug-pattern.ss"))
    (check (pattern-search-snapshot "poo slot cache computed"
                                    slot-cache
                                    (hash-get slot-cache 'missing)
                                    (hash-get slot-cache 'next))
           => (snapshot-load "t/snapshots/poo-slot-cache-pattern.ss"))
    (check (pattern-search-snapshot "poo json fallback"
                                    io-json
                                    (hash-get io-json 'missing)
                                    (hash-get io-json 'next))
           => (snapshot-load "t/snapshots/poo-io-json-fallback-partial.ss"))
    (check (pattern-search-snapshot "poo lens slot-lens"
                                    lens
                                    (hash-get lens 'missing)
                                    (hash-get lens 'next))
           => (snapshot-load "t/snapshots/poo-lens-pattern.ss"))
    (check (pattern-search-snapshot "poo sealed validate"
                                    type-validation
                                    (hash-get type-validation 'missing)
                                    (hash-get type-validation 'next))
           => (snapshot-load "t/snapshots/poo-type-validation-pattern.ss"))))

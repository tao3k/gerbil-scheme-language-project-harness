;;; -*- Gerbil -*-
(import :std/test
        :extensions/facade
        :parser/facade
        :parser/typed-contract-scheme
        :protocol/json
        :protocol/structural-facts
        :std/srfi/13)
(export parser-test-part-8)

;; : (-> Selector Relpath Boolean )
(def (selector-owner? selector path)
  (and (string? selector)
       (string-prefix? (string-append path ":") selector)))

;; : (-> (List CallFact) Argument FindCallWithArgument )
(def (find-call-with-argument calls argument)
  (find (lambda (call)
          (equal? (call-fact-arguments call) [argument]))
        calls))
;; : (-> (List QualityFacet) QualityFacet Boolean )
(def (quality-facet-member? facets facet)
  (not (not (member facet facets))))
;; : (-> (List MacroFact) String MacroFact )
(def (find-macro facts name)
  (find (lambda (fact)
          (equal? (macro-fact-name fact) name))
        facts))
;; : (-> (List HigherOrderFact) String String String (List HigherOrderFact) )
(def (find-higher-order facts name role caller)
  (find (lambda (fact)
          (and (equal? (higher-order-fact-name fact) name)
               (equal? (higher-order-fact-role fact) role)
               (equal? (or (higher-order-fact-caller fact) "") caller)))
        facts))
;; : (-> (List ControlFlowFact) String String String (List ControlFlowFact) )
(def (find-control-flow facts name role caller)
  (find (lambda (fact)
          (and (equal? (control-flow-fact-name fact) name)
               (equal? (control-flow-fact-role fact) role)
               (equal? (or (control-flow-fact-caller fact) "") caller)))
        facts))
;; : (-> (List TypedContractFact) String (List TypedContractFact) )
(def (find-typed-contract facts name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        facts))
;; : (-> (List PredicateFamilyFact) String PredicateFamilyFact )
(def (find-predicate-family facts subject)
  (find (lambda (fact)
          (equal? (predicate-family-fact-subject fact) subject))
        facts))
;; : (-> (List FieldAccessPatternFact) String FieldAccessPatternFact )
(def (find-field-access-pattern facts field-key)
  (find (lambda (fact)
          (equal? (field-access-pattern-fact-field-key fact) field-key))
        facts))
;; : (-> (List BooleanConditionFact) String BooleanConditionFact )
(def (find-boolean-condition facts caller)
  (find (lambda (fact)
          (equal? (boolean-condition-fact-caller fact) caller))
        facts))
;; : (-> (List LoopDriverFact) String LoopDriverFact )
(def (find-loop-driver facts caller)
  (find (lambda (fact)
          (equal? (loop-driver-fact-caller fact) caller))
        facts))
;; : (-> (List FunctionQualityProfile) String FunctionQualityProfile )
(def (find-function-quality-profile profiles name)
  (find (lambda (profile)
          (equal? (function-quality-profile-name profile) name))
        profiles))
;; : (-> (List SourceFile) Relpath SourceFile )
(def (find-source-file files path)
  (find (lambda (file)
          (equal? (source-file-path file) path))
        files))
;; : (-> (List PooFormFact) String PooFormFact )
(def (find-poo-form facts name)
  (find (lambda (fact)
          (equal? (poo-form-fact-name fact) name))
        facts))
;; : (-> (List PooFormFact) String String PooFormFact )
(def (find-poo-form-role facts name role)
  (find (lambda (fact)
          (and (equal? (poo-form-fact-name fact) name)
               (equal? (poo-form-fact-role fact) role)))
        facts))
;; ParsedData
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; TestSuite
(def parser-test-part-8
  (test-suite "gerbil scheme harness parser part 8"
    (test-case "source path class owns build policy scope"
          (check (source-path-class "gerbil.pkg") => "config")
          (check (source-path-class "build.ss") => "package-build")
          (check (source-path-class "build-support/provider-cli.ss")
                 => "build-support-runtime")
          (check (source-path-class "t/scenarios/policy/functional-idiom/input/src/orders/core.ss")
                 => "policy-scenario")
          (check (source-path-class "t/fixtures/parser/raw.ss") => "fixture")
          (check (source-path-class "t/snapshots/policy-functional-idiom.ss")
                 => "snapshot-output")
          (check (source-path-class "src/main.ss") => "runtime-source"))
    (test-case "scheme typed contracts validate type constructor applications"
          (let* ((list-expr
                  (scheme-type-expression-text-json "(List TypeFinding)"))
                 (list-shape (hash-get list-expr 'shape))
                 (list-param (car (hash-get list-shape 'parameters)))
                 (forall-signature
                  (scheme-type-signature-json
                   "(forall (a) (-> (-> a Boolean) (Array a) Boolean))"))
                 (arrow (hash-get forall-signature 'arrow))
                 (array-input (cadr (hash-get arrow 'inputs)))
                 (array-param (car (hash-get array-input 'parameters)))
                 (unbound-expr
                  (scheme-type-expression-text-json "(Array a)"))
                 (unbound-shape (hash-get unbound-expr 'shape))
                 (unbound-param (car (hash-get unbound-shape 'parameters))))
            (check (hash-get list-expr 'valid) => #t)
            (check (hash-get list-shape 'kind) => "container")
            (check (hash-get list-shape 'name) => "List")
            (check (hash-get list-param 'kind) => "name")
            (check (hash-get list-param 'name) => "TypeFinding")
            (check (hash-get list-param 'role) => "type-name")
            (check (hash-get forall-signature 'valid) => #t)
            (check (hash-get array-input 'kind) => "container")
            (check (hash-get array-input 'name) => "Array")
            (check (hash-get array-param 'role) => "type-variable")
            (check (hash-get array-param 'name) => "a")
            (check (hash-get array-param 'bound) => #t)
            (check (hash-get unbound-expr 'valid) => #f)
            (check (hash-get unbound-param 'role) => "type-variable")
            (check (hash-get unbound-param 'bound) => #f)
            (check (hash-get unbound-expr 'diagnostics)
                   => ["unbound-type-variable:a"])))
    (test-case "comment quality preserves module comment after script shebang"
          (let* ((root (path-normalize ".run/parser-shebang-module-comment"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/script.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/shebang-comment)\n")
            (write-text
             source-path
             "#!/usr/bin/env gxi\n\
;;; -*- Gerbil -*-\n\
;;; Boundary:\n\
;;; - Script materializer owns runtime artifact projection.\n\
\n\
(def (main . args) args)\n")
            (let* ((file (parse-source-file root "src/script.ss"))
                   (module-fact
                    (find (lambda (fact)
                            (equal? (comment-quality-fact-target-kind fact)
                                    "module"))
                          (source-file-comment-quality-facts file))))
              (check (comment-quality-fact-comment-lines module-fact)
                     => ["Boundary:"
                         "- Script materializer owns runtime artifact projection."])
              (check (comment-quality-fact-quality module-fact)
                     => "engineering-grade"))))
    (test-case "comment quality ignores scheme comment markers in typed docs"
          (let* ((root (path-normalize ".run/parser-typed-doc-semicolon"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/typed-doc.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/typed-doc-semicolon)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
;;; Boundary:\n\
;;; - Module owns typed doc semicolon parsing fixtures.\n\
\n\
;;; Boundary:\n\
;;; - Parser docs may mention Scheme comment markers as syntax.\n\
;; documented-helper\n\
;;   : (-> String String)\n\
;;   | doc m%\n\
;;       `documented-helper value` describes the `;; :` signature marker.\n\
;;\n\
;;       # Examples\n\
;;       ```scheme\n\
;;       (documented-helper \"x\")\n\
;;       ;; => \"x\"\n\
;;       ```\n\
;;     %\n\
(def (documented-helper value) value)\n")
            (let* ((file (parse-source-file root "src/typed-doc.ss"))
                   (fact
                    (find (lambda (item)
                            (equal? (comment-quality-fact-target-name item)
                                    "documented-helper"))
                          (source-file-comment-quality-facts file))))
              (check (comment-quality-fact-comment-kind fact) => "boundary")
              (check (comment-quality-fact-quality fact)
                     => "engineering-grade"))))
    (test-case "function quality profile distinguishes factories from wrapper drift"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/higher-order.ss"))
                 (specialized-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "specialized-label"))
                 (wrapper-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "wrapper-label")))
            (check (not (not (member "higher-order-constructor-abstraction"
                                      (function-quality-profile-quality-facets
                                       specialized-profile))))
                   => #t)
            (check (not (not (member "arity-specialized-function-factory"
                                      (function-quality-profile-quality-facets
                                       specialized-profile))))
                   => #t)
            (check (member "wrapper-lambda-drift"
                           (function-quality-profile-quality-facets
                            specialized-profile))
                   => #f)
            (check (not (not (member "wrapper-lambda-drift"
                                      (function-quality-profile-quality-facets
                                       wrapper-profile))))
                   => #t)
            (check (not (not (member "function-specialization-opportunity"
                                      (function-quality-profile-quality-facets
                                       wrapper-profile))))
                   => #t)
            (check (function-quality-profile-suggested-repair-class
                    wrapper-profile)
                   => "typed-combinator-style")
            (check (not (not (string-contains
                              (function-quality-profile-advice wrapper-profile)
                              "curry/rcurry")))
                   => #t)))
    (test-case "project package infers runtime roots from build script"
          (let* ((root (path-normalize ".run/parser-build-scope"))
                 (lib-dir (string-append root "/lib"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (build-path (string-append root "/build.ss"))
                 (lib-path (string-append lib-dir "/main.ss"))
                 (flat-path (string-append root "/cli.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir lib-dir)
            (write-text package-path
                        "(package: sample/build-scope)\n")
            (write-text build-path
                        ";;; -*- Gerbil -*-\n(defbuild-script '(\"lib/main\" \"cli\"))\n")
            (write-text lib-path "(package: sample/build-scope/main)\n(def answer 42)\n")
            (write-text flat-path "(package: sample/build-scope/cli)\n(def (main . args) args)\n")
            (let* ((index (collect-project root))
                   (package (project-index-package index))
                   (scope (project-package-source-scope-policy package)))
              (check (map source-file-path (project-index-files index))
                     => ["build.ss" "cli.ss" "gerbil.pkg" "lib/main.ss"])
              (check (source-scope-policy-roots scope) => [])
              (check (source-scope-policy-runtime-roots scope) => ["lib" "."])
              (check (source-scope-policy-explanation scope)
                     => "Inferred from build.ss defbuild-script targets."))))
    (test-case "project package dependency activates poo extension"
          (let* ((root (path-normalize ".run/parser-poo-dependency"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/main.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path
                        "(package: sample/app\n depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
            (write-text source-path "(package: sample/app/main)\n(def answer 42)\n")
            (let* ((index (collect-project root))
                   (extensions (project-extension-json index))
                   (extension (car extensions)))
              (check (project-package-name (project-index-package index)) => "sample/app")
              (check (hash-get extension 'name) => "poo")
              (check (hash-get extension 'activation) => "gerbil.pkg")
              (check (hash-get extension 'dependencyMode) => "required")
              (check (hash-get extension 'packageManager) => "gxpkg")
              (check (hash-get extension 'package) => "sample/app"))))
    (test-case "typed contract parser accepts scheme native comment blocks"
          (let* ((root (path-normalize ".run/parser-typed-comment-block"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/typed-comment)\n")
            (write-text
             source-path
             "(package: sample/typed-comment/core)\n\
;; : (forall (a)\n\
;;     (-> (-> a a Order)\n\
;;         (List a)\n\
;;         (List a)\n\
;;         Order))\n\
;; | type Order = (U 'Lesser 'Equal 'Greater)\n\
(def (compare order left right)\n\
  (order left right))\n\
\n\
;; generate\n\
;;   : (forall (a)\n\
;;       (-> (-> Number a)\n\
;;           Number\n\
;;           (Vector a)))\n\
;;   | contract (-> procedure? natural? vector?)\n\
;;   | type Nat = (Refine Number natural?)\n\
;;   | type Result a = (Values (Vector a) (U 'Ok 'Empty))\n\
;;   | requires (natural? n)\n\
;;   | warning n must be natural for deterministic vector size\n\
;;   | rationale callers validate n through natural?\n\
;;   | doc m%\n\
;;       `generate f n` returns a vector of n generated values.\n\
;;\n\
;;       # Examples\n\
;;\n\
;;       ```scheme\n\
;;       (generate (lambda (x) x) 0)\n\
;;       ;; => #()\n\
;;       ```\n\
;;     %\n\
(def (generate f n)\n\
  (vector))\n")
            (let* ((index (collect-project root))
                   (source (find-source-file (project-index-files index)
                                             "src/core.ss"))
                   (contract (find-typed-contract
                              (source-file-typed-contract-facts source)
                              "compare"))
                   (generate-contract
                    (find-typed-contract
                     (source-file-typed-contract-facts source)
                     "generate")))
              (check (typed-contract-fact-contract contract)
                     => "(forall (a) (-> (-> a a Order) (List a) (List a) Order))")
              (check (typed-contract-fact-contract-output contract) => "Order")
              (check (typed-contract-fact-contract-inputs contract)
                     => ["(-> a a Order)" "(List a)" "(List a)"])
              (check (typed-contract-fact-contract-input-count contract) => 3)
              (check (typed-contract-fact-group-count contract) => 0)
              (check (typed-contract-fact-arity-alignment contract) => "aligned")
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets contract)
                      "scheme-native-block")
                     => #t)
              (check (typed-contract-fact-contract generate-contract)
                     => "(forall (a) (-> (-> Number a) Number (Vector a)))")
              (check (typed-contract-fact-contract-output generate-contract)
                     => "(Vector a)")
              (check (typed-contract-fact-contract-inputs generate-contract)
                     => ["(-> Number a)" "Number"])
              (check (typed-contract-fact-contract-input-count generate-contract)
                     => 2)
              (check (typed-contract-fact-group-count generate-contract) => 0)
              (check (typed-contract-fact-arity-alignment generate-contract)
                     => "aligned")
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "runtime-contract-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "local-type-environment")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "refinement-type-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "precondition-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "warning-contract-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "rationale-contract-block")
                     => #t)
              (let* ((typed-comment
                      (typed-contract-fact-typed-comment generate-contract))
                     (local-type (car (hash-get typed-comment 'localTypes)))
                     (result-type (cadr (hash-get typed-comment 'localTypes)))
                     (signature-type (hash-get typed-comment 'signatureType))
                     (signature-arrow (hash-get signature-type 'arrow))
                     (signature-output (hash-get signature-arrow 'output))
                     (result-expression
                      (hash-get result-type 'expressionType))
                     (result-shape (hash-get result-expression 'shape))
                     (result-union
                      (cadr (hash-get result-shape 'values)))
                     (runtime-contract
                      (car (hash-get typed-comment 'runtimeContractsDetailed)))
                     (requires-predicate
                      (car (hash-get typed-comment 'requiresDetailed)))
                     (doc (car (hash-get typed-comment 'docs)))
                     (doc-example (car (hash-get doc 'examples))))
                (check (hash-get typed-comment 'syntax) => "scheme-native")
                (check (hash-get typed-comment 'fullForm) => #t)
                (check (hash-get typed-comment 'leadingName) => "generate")
                (check (hash-get signature-type 'valid) => #t)
                (check (hash-get signature-type 'forall) => ["a"])
                (check (hash-get signature-arrow 'inputCount) => 2)
                (check (hash-get signature-output 'kind) => "container")
                (check (hash-get signature-output 'name) => "Vector")
                (check (hash-get local-type 'name) => "Nat")
                (check (hash-get local-type 'expression)
                       => "(Refine Number natural?)")
                (check (hash-get (hash-get local-type 'expressionType) 'valid)
                       => #t)
                (check (hash-get result-type 'name) => "Result")
                (check (hash-get result-type 'parameters) => ["a"])
                (check (hash-get result-expression 'valid) => #t)
                (check (hash-get result-shape 'kind) => "values")
                (check (hash-get result-union 'kind) => "union")
                (check (hash-get typed-comment 'runtimeContracts)
                       => ["(-> procedure? natural? vector?)"])
                (check (hash-get runtime-contract 'valid) => #t)
                (check (hash-get runtime-contract 'inputPredicates)
                       => ["procedure?" "natural?"])
                (check (hash-get runtime-contract 'outputPredicate)
                       => "vector?")
                (check (hash-get typed-comment 'requires)
                       => ["(natural? n)"])
                (check (hash-get requires-predicate 'valid) => #t)
                (check (hash-get requires-predicate 'name) => "natural?")
                (check (hash-get requires-predicate 'arguments) => ["n"])
                (check (hash-get typed-comment 'warnings)
                       => ["n must be natural for deterministic vector size"])
                (check (hash-get typed-comment 'rationales)
                       => ["callers validate n through natural?"])
                (check (hash-get typed-comment 'refinements)
                       => ["Nat = (Refine Number natural?)"])
                (check (hash-get doc 'marker) => "m%")
                (check (hash-get doc 'body)
                       => "`generate f n` returns a vector of n generated values.\n\n# Examples\n\n```scheme\n(generate (lambda (x) x) 0)\n;; => #()\n```")
                (check (hash-get doc 'hasExamples) => #t)
                (check (hash-get doc 'hasResultExamples) => #t)
                (check (hash-get doc-example 'language) => "scheme")
                (check (hash-get doc-example 'code)
                       => "(generate (lambda (x) x) 0)")
                (check (hash-get doc-example 'expected) => "#()")
                (check (hash-get doc-example 'hasExpectedResult) => #t)
                (let* ((structural-facts (structural-syntax-fact-json source))
                       (structural-row
                        (find (lambda (fact)
                                (and (equal? (hash-get fact 'languageKind)
                                             "typed-combinator-contract")
                                     (equal? (hash-get fact 'name)
                                             "generate")))
                              structural-facts))
                       (fields (hash-get structural-row 'fields))
                       (json-typed-comment
                        (hash-get fields 'typedComment)))
                  (check (hash-get fields 'contractOutput) => "(Vector a)")
                  (check (hash-get json-typed-comment 'leadingName)
                         => "generate")
                  (check (hash-get json-typed-comment 'runtimeContracts)
                         => ["(-> procedure? natural? vector?)"])
                  (check (hash-get
                          (car (hash-get json-typed-comment 'docs))
                          'hasResultExamples)
                         => #t)
                  (check (hash-get (hash-get json-typed-comment 'signatureType)
                                   'valid)
                         => #t))
                (check (hash-get (scheme-type-expression-text-json "(Hash String)")
                                 'diagnostics)
                       => ["Hash-requires-key-and-value"])
                (check (hash-get (scheme-type-signature-json "(-> Output)")
                                 'diagnostics)
                       => ["signature-arrow-too-short"
                           "arrow-requires-input-and-output"])))))))

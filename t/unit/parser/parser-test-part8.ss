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
  (if (member facet facets) #t #f))
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
    (test-case "boolean condition facts include multi-arity path predicates"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/boolean-condition.ss"))
                 (fact
                  (find-boolean-condition
                   (source-file-boolean-condition-facts file)
                   "path-matches-token?"))
                 (callees (boolean-condition-fact-condition-callees fact)))
            (check (source-file-parse-error file) => #f)
            (check (boolean-condition-fact-formals fact) => ["relpath" "token"])
            (check (boolean-condition-fact-condition-count fact) => 6)
            (check (if (member "string-prefix?" callees) #t #f) => #t)
            (check (if (member "string-suffix?" callees) #t #f) => #t)
            (check (if (member "string-contains" callees) #t #f) => #t)
            (check (if (member "not" callees) #t #f) => #t)))
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
                 (unbound-param (car (hash-get unbound-shape 'parameters)))
                 (hash-expr
                  (scheme-type-expression-text-json "(Hash String Number)"))
                 (hash-type-spec (hash-get hash-expr 'typeSpec))
                 (hash-key-type (car (hash-get hash-type-spec 'params)))
                 (hash-value-type (cadr (hash-get hash-type-spec 'params)))
                 (refine-expr
                  (scheme-type-expression-text-json
                   "(Refine Number natural?)"))
                 (refine-type-spec (hash-get refine-expr 'typeSpec))
                 (application-signature
                  (scheme-type-signature-json
                   "(forall (a) (-> (NonEmptyList a) a))"))
                 (application-param
                  (car
                   (hash-get
                    (hash-get application-signature 'typeSpec)
                    'params))))
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
                   => ["unbound-type-variable:a"])
            (check (hash-get hash-expr 'valid) => #t)
            (check (hash-get hash-type-spec 'kind) => "hash")
            (check (hash-get hash-type-spec 'valid) => #t)
            (check (hash-get hash-type-spec 'diagnostics) => [])
            (check (hash-get hash-key-type 'display) => "String")
            (check (hash-get hash-value-type 'display) => "Number")
            (check (hash-get refine-expr 'valid) => #t)
            (check (hash-get refine-type-spec 'kind) => "refine")
            (check (hash-get refine-type-spec 'valid) => #t)
            (check (hash-get refine-type-spec 'name) => "natural?")
            (check (hash-get application-signature 'valid) => #t)
            (check (hash-get application-param 'kind) => "application")
            (check (hash-get application-param 'display)
                   => "(NonEmptyList a)")))
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
                   "wrapper-label"))
                 (match-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "matched-tags"))
                 (eta-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "total"))
                 (match-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "lambda"
                   "lambda-match-opportunity"
                   "matched-tags"))
                 (eta-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "lambda"
                   "eta-wrapper-lambda"
                   "total")))
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
                   => #t)
            (check (not match-fact) => #f)
            (check (not (not (member "lambda-match-rewrite-opportunity"
                                      (function-quality-profile-quality-facets
                                       match-profile))))
                   => #t)
            (check (function-quality-profile-suggested-repair-class
                    match-profile)
                   => "typed-combinator-style")
            (check (not (not (string-contains
                              (function-quality-profile-advice match-profile)
                              "lambda-match")))
                   => #t)
            (check (not eta-fact) => #f)
            (check (not (not (member "eta-wrapper-drift"
                                      (function-quality-profile-quality-facets
                                       eta-profile))))
                   => #t)))
    (test-case "parser exposes boolean normalization scaffold facts"
          (let* ((root (path-normalize ".run/parser-boolean-normalization"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/boolean-normalization)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/boolean-normalization)\n\
;; : (-> (List Symbol) Boolean)\n\
(def (selected? choices)\n\
  (not (not (member 'ready choices))))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (fact
                    (find (lambda (item)
                            (equal? (boolean-condition-fact-role item)
                                    "boolean-normalization-scaffold"))
                          (source-file-boolean-condition-facts file))))
              (check (not fact) => #f)
              (check (boolean-condition-fact-caller fact) => "selected?")
              (check (quality-facet-member?
                      (boolean-condition-fact-quality-facets fact)
                      "boolean-normalization-drift")
                     => #t)
              (check (quality-facet-member?
                      (boolean-condition-fact-quality-facets fact)
                      "generated-scaffold-shape")
                     => #t))))
    (test-case "parser keeps boolean normalization AST-owned"
          (let* ((root (path-normalize ".run/parser-boolean-normalization-ast"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/boolean-normalization-ast)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/boolean-normalization-ast)\n\
;; : (-> Boolean Boolean Boolean)\n\
(def (mixed? left right)\n\
  (not (or left (not right))))\n\
;; : (-> Symbol Symbol)\n\
(def (quoted-shape value)\n\
  '(not (not value)))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (facts
                    (filter (lambda (item)
                              (equal? (boolean-condition-fact-role item)
                                      "boolean-normalization-scaffold"))
                            (source-file-boolean-condition-facts file))))
              (check facts => []))))
    (test-case "parser exposes inline alist lookup as AST-owned field access"
          (let* ((root (path-normalize ".run/parser-inline-alist-access"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/inline-alist)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/inline-alist)\n\
;; : (-> Profile Value)\n\
(def (profile-name profile)\n\
  (cdr (assq 'name profile)))\n\
;; : (-> Profile Value)\n\
(def (profile-owner profile)\n\
  (cdr (assq 'owner profile)))\n\
;; : (-> Value Value)\n\
(def (quoted-shape value)\n\
  '(cdr (assq 'name profile)))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (facts (source-file-field-access-pattern-facts file))
                   (name-fact (find-field-access-pattern facts "alist:name"))
                   (owner-fact (find-field-access-pattern facts "alist:owner")))
              (check (not name-fact) => #f)
              (check (field-access-pattern-fact-role name-fact)
                     => "inline-alist-lookup")
              (check (field-access-pattern-fact-callers name-fact)
                     => ["profile-name"])
              (check (field-access-pattern-fact-access-count name-fact) => 1)
              (check (quality-facet-member?
                      (field-access-pattern-fact-quality-facets name-fact)
                      "inline-alist-lookup-drift")
                     => #t)
              (check (not owner-fact) => #f)
              (check (field-access-pattern-fact-callers owner-fact)
                     => ["profile-owner"]))))
    (test-case "parser exposes poo method bodies and gerbil-utils fun helpers"
          (let* ((root (path-normalize ".run/parser-poo-method-fun"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/poo-method-fun)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/poo-method-fun/core)\n\
;; Integer\n\
(define-type (Box @ [Wrapper.] T .wrap .unwrap)\n\
  .map: (lambda (f x) (.wrap (f (.unwrap x))))\n\
  .unwrap*: (cut .unwrap <>)\n\
  .wrap*: .wrap\n\
  .empty: []\n\
  .validate: (lambda (super) (lambda (value) (super value))))\n\
;; : (-> (List String) (List String) )\n\
(def (label-items items)\n\
  (map (fun (label-item item)\n\
         (string-append \"item:\" item))\n\
       items))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                 (box (find-poo-form (source-file-poo-forms file) "Box"))
                 (box-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "Box"))
                 (fun-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "fun"
                   "named-lambda-abstraction"
                   "label-items"))
                 (map-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "map"
                   "sequence-map"
                   "label-items")))
            (check (not (not box)) => #t)
            (check (not (not (member ".wrap" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member ".unwrap" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member ".map" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member ".unwrap*" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member "methodSlot:.map"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.map:lambda"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBodyQuality:.map:lambda-drift"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodTableBody:lambda-drift"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.unwrap*:partial-application"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBodyQuality:.unwrap*:combinator"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodTableBody:combinator"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.wrap*:identifier"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.empty:call:@list"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (member "methodBodyQuality:.empty:low-level"
                           (poo-form-fact-options box))
                   => #f)
            (check (not (not (member "methodBodyQuality:.validate:validation-boundary"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (member "methodBodyQuality:.validate:lambda-drift"
                           (poo-form-fact-options box))
                   => #f)
            (check (not box-profile) => #f)
            (check (quality-facet-member?
                    (function-quality-profile-quality-facets box-profile)
                    "method-table-lambda-drift")
                   => #t)
            (check (quality-facet-member?
                    (function-quality-profile-quality-facets box-profile)
                    "method-table-validation-boundary")
                   => #t)
            (check (quality-facet-member?
                    (function-quality-profile-quality-facets box-profile)
                    "method-table-combinator-body")
                   => #t)
            (check (function-quality-profile-suggested-repair-class
                    box-profile)
                   => "poo-policy")
            (check (not (not fun-fact)) => #t)
            (check (higher-order-fact-operand-count fun-fact) => 2)
            (check (not (not (member "named-lambda-helper"
                                     (higher-order-quality-facets fun-fact))))
                   => #t)
            (check (not (not map-fact)) => #t)
            (check (not (not (member "expression-level-composition"
                                     (higher-order-quality-facets map-fact))))
                   => #t))))
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
                     (signature-type-spec (hash-get signature-type 'typeSpec))
                     (signature-output-spec (hash-get signature-type-spec 'result))
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
                (check (hash-get signature-type-spec 'display)
                       => "(function ((function (Number) a) Number) (vector a))")
                (check (hash-get signature-output-spec 'display)
                       => "(vector a)")
                (check (hash-get signature-output-spec 'kind) => "vector")
                (check (hash-get (hash-get signature-arrow 'typeSpec) 'display)
                       => "(function ((function (Number) a) Number) (vector a))")
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
                         => #t)
                  (check (hash-get
                          (hash-get (hash-get json-typed-comment 'signatureType)
                                    'typeSpec)
                          'display)
                         => "(function ((function (Number) a) Number) (vector a))"))
                (let* ((bad-hash
                        (scheme-type-expression-text-json "(Hash String)"))
                       (bad-hash-type (hash-get bad-hash 'typeSpec))
                       (bad-hash-diagnostic
                        (car (hash-get bad-hash-type 'diagnosticFacts))))
                  (check (hash-get bad-hash 'diagnostics)
                         => ["Hash-requires-key-and-value"])
                  (check (hash-get bad-hash-type 'valid) => #f)
                  (check (hash-get bad-hash-type 'diagnostics)
                         => ["hash-value:unknown-type"])
                  (check (hash-get bad-hash-diagnostic 'code)
                         => "unknown-type")
                  (check (hash-get bad-hash-diagnostic 'path)
                         => ["hash-value"])
                  (check (hash-get bad-hash-diagnostic 'category)
                         => "shape"))
                (check (hash-get (scheme-type-signature-json "(-> Output)")
                                 'diagnostics)
                       => ["signature-arrow-too-short"
                           "arrow-requires-input-and-output"])))))))

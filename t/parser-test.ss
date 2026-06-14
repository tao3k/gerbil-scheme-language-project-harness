;;; -*- Gerbil -*-
(import :std/test
        :extensions/facade
        :parser/facade
        :std/srfi/13)
(export parser-test)

;; Boolean <- Selector Relpath
(def (selector-owner? selector path)
  (and (string? selector)
       (string-prefix? (string-append path ":") selector)))

;; FindCallWithArgument <- (List CallFact) Argument
(def (find-call-with-argument calls argument)
  (find (lambda (call)
          (equal? (call-fact-arguments call) [argument]))
        calls))
;; Boolean <- (List QualityFacet) QualityFacet
(def (quality-facet-member? facets facet)
  (not (not (member facet facets))))
;; MacroFact <- (List MacroFact) String
(def (find-macro facts name)
  (find (lambda (fact)
          (equal? (macro-fact-name fact) name))
        facts))
;; (List HigherOrderFact) <- (List HigherOrderFact) String String String
(def (find-higher-order facts name role caller)
  (find (lambda (fact)
          (and (equal? (higher-order-fact-name fact) name)
               (equal? (higher-order-fact-role fact) role)
               (equal? (or (higher-order-fact-caller fact) "") caller)))
        facts))
;; (List ControlFlowFact) <- (List ControlFlowFact) String String String
(def (find-control-flow facts name role caller)
  (find (lambda (fact)
          (and (equal? (control-flow-fact-name fact) name)
               (equal? (control-flow-fact-role fact) role)
               (equal? (or (control-flow-fact-caller fact) "") caller)))
        facts))
;; (List TypedContractFact) <- (List TypedContractFact) String
(def (find-typed-contract facts name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        facts))
;; ParsedData
(def parser-test
  (test-suite "gerbil scheme harness parser"
    (test-case "native reader captures package and definitions"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "t/fixtures/sample.ss")))
        (check (source-file-package file) => "sample/sample")
        (check (map definition-name (source-file-definitions file))
               => ["answer" "make-answer"])
        (check (map definition-formals (source-file-definitions file))
               => ['() '()])
        (check (map definition-arity (source-file-definitions file))
               => [0 0])
        (check (map top-form-head (source-file-forms file))
               => ["import" "export" "def" "def"])
        (check (map top-form-kind (source-file-forms file))
               => ["import" "export" "definition" "definition"])
        (check (selector-owner? (top-form-selector (car (source-file-forms file)))
                                "t/fixtures/sample.ss")
               => #t)
        (check (>= (source-file-line-count file) 12) => #t)))
    (test-case "native reader captures definition formals"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "t/fixtures/formals.ss")))
        (check (map definition-name (source-file-definitions file))
               => ["sum-two" "collect"])
        (check (map definition-formals (source-file-definitions file))
               => [["x" "y"] ["xs"]])
        (check (map definition-arity (source-file-definitions file))
               => [2 1])))
    (test-case "native reader captures call facts"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "t/fixtures/formals.ss"))
             (calls (source-file-calls file)))
        (check (map call-fact-callee calls) => ["+"])
        (check (map call-fact-arity calls) => [2])
        (check (map call-fact-arguments calls) => [["x" "y"]])
        (check (map call-fact-argument-types calls) => [[#f #f]])
        (check (map call-fact-caller calls) => ["sum-two"])
        (check (map (lambda (selector)
                      (selector-owner? selector "t/fixtures/formals.ss"))
                    (map call-fact-selector calls))
               => [#t])))
    (test-case "native reader captures complex Gerbil syntax facts"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "t/fixtures/parser/complex-syntax.ss"))
             (macros (source-file-macros file))
             (with-widget-macro (find-macro macros "with-widget"))
             (capture-safe-macro (find-macro macros "capture-safe")))
        (check (source-file-parse-error file) => #f)
        (check (map definition-name (source-file-definitions file))
               => ["with-widget"
                   "capture-safe"
                   "<Widget>"
                   ":render"
                   "<Renderable>"
                   ":render"
                   "make-widget"
                   "dispatch"
                   "select"])
        (check (map module-import-fact-module (source-file-module-imports file))
               => [":std/misc/path"
                   ":std/misc/repr"
                   ":std/misc/hash"
                   ":std/misc/list"
                   ":std/stxutil"
                   ":std/text/json"
                   ":std/sugar"])
        (check (map module-import-fact-modifier (source-file-module-imports file))
               => ["for-template" "phi:" "except-in" "rename-in"
                   "for-syntax" "only-in" "direct"])
        (check (map module-import-fact-phase (source-file-module-imports file))
               => ["template" "phase:1" "runtime" "runtime"
                   "syntax" "runtime" "runtime"])
        (check (map macro-fact-name macros)
               => ["with-widget" "capture-safe"])
        (check (map macro-fact-hygienic macros)
               => [#t #t])
        (check (quality-facet-member? (macro-fact-quality-facets with-widget-macro)
                                      "hygienic-macro")
               => #t)
        (check (quality-facet-member? (macro-fact-quality-facets with-widget-macro)
                                      "macro-sugar")
               => #t)
        (check (quality-facet-member? (macro-fact-quality-facets capture-safe-macro)
                                      "syntax-case-transformer")
               => #t)
        (check (quality-facet-member? (macro-fact-quality-facets capture-safe-macro)
                                      "syntax-template-witness")
               => #t)
        (check (map poo-form-fact-role (source-file-poo-forms file))
               => ["class" "generic" "protocol" "method"])
        (check (map poo-form-fact-generic (source-file-poo-forms file))
               => (list #f ":render" #f ":render"))
        (check (map poo-form-fact-receiver (source-file-poo-forms file))
               => (list #f #f #f "widget"))
        (check (map poo-form-fact-receiver-type (source-file-poo-forms file))
               => (list #f #f #f "<Widget>"))
        (check (map poo-form-fact-supers (source-file-poo-forms file))
               => (list [":object"] '() '() '()))
        (check (map poo-form-fact-slots (source-file-poo-forms file))
               => (list ["name" "count"] '() '() '()))
        (check (map poo-form-fact-options (source-file-poo-forms file))
               => (list ["transparent:"] '() '() '()))
        (check (map poo-form-fact-specializers (source-file-poo-forms file))
               => (list '() '() '() ["widget:<Widget>"]))
        (check (map poo-form-fact-specializer-types (source-file-poo-forms file))
               => (list '() '() '() ["<Widget>"]))
        (check (map binding-fact-kind (source-file-bindings file))
               => ["macro-formal"
                   "macro-formal"
                   "macro-formal"
                   "let*"
                   "let*"
                   "let*"
                   "let"
                   "formal"
                   "formal"
                   "formal"
                   "formal"])
        (check (map call-fact-callee (source-file-calls file))
               => [":render"
                   "open-input-string"
                   "read-json"
                   "displayln"
                   "make-<Widget>"
                   "with-widget"
                   "make-widget"
                   "make-widget"
                   "dispatch"
                   "make-widget"])
        (check (map (lambda (selector)
                      (selector-owner? selector "t/fixtures/parser/complex-syntax.ss"))
                    (map call-fact-selector (source-file-calls file)))
               => [#t #t #t #t #t #t #t #t #t #t])))
    (test-case "native reader captures higher-order syntax facts"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "t/fixtures/parser/higher-order.ss"))
             (facts (source-file-higher-order-forms file))
             (select-definition
              (find (lambda (definition)
                      (equal? (definition-name definition) "select"))
                    (source-file-definitions file)))
             (bump-definition
              (find (lambda (definition)
                      (equal? (definition-name definition) "bump"))
                    (source-file-definitions file)))
             (case-lambda-fact
              (find-higher-order facts "case-lambda" "multi-arity-function" "select"))
             (map-fact
              (find-higher-order facts "map" "sequence-map" "names"))
             (map-lambda
              (find-higher-order facts "lambda" "anonymous-function" "names"))
             (filter-fact
              (find-higher-order facts "filter" "sequence-filter" "positives"))
             (filter-map-fact
              (find-higher-order facts "filter-map" "sequence-filter-map" "positive-names"))
             (predicate-fact
              (find-higher-order facts "ormap" "sequence-predicate" "any-positive?"))
             (search-fact
              (find-higher-order facts "find" "sequence-search" "first-positive"))
             (fold-fact
              (find-higher-order facts "fold-left" "sequence-fold" "total"))
             (cut-fact
              (find-higher-order facts "cut" "partial-application" "bump"))
             (for-fold-fact
              (find-higher-order facts "for/fold" "loop-fold" "counted"))
             (autocurry-fact
              (find-higher-order facts "defn" "autocurry-semantics" "autocurried"))
             (pipeline-fact
              (find-higher-order facts "!>" "pipeline-composition" "pipeline"))
             (rcompose-fact
              (find-higher-order facts "rcompose" "function-composition" "compose-values"))
             (syntax-helper-fact
              (find-higher-order facts "stx-apply" "syntax-helper-dsl" "syntax-helper"))
             (generator-fact
              (find-higher-order facts "generating<-for-each" "generator-transform" "generator-source"))
             (generator-thread-fact
              (find-higher-order facts "generating<-cothread" "generator-control-inversion" "generator-thread"))
             (peekable-fact
              (find-higher-order facts ":peekable-iter" "stateful-protocol-wrapper" "peekable")))
        (check (source-file-parse-error file) => #f)
        (check (not (null? facts)) => #t)
        (check (definition-formals select-definition) => ["x"])
        (check (definition-arity select-definition) => 1)
        (check (definition-formals bump-definition) => ["<>"])
        (check (definition-arity bump-definition) => 1)
        (check (higher-order-fact-arities case-lambda-fact) => [0 1])
        (check (higher-order-fact-operand-count map-fact) => 2)
        (check (higher-order-fact-arities map-lambda) => [1])
        (check (higher-order-fact-formals map-lambda) => ["widget"])
        (check (higher-order-fact-operand-count filter-fact) => 2)
        (check (higher-order-fact-operand-count filter-map-fact) => 2)
        (check (higher-order-fact-operand-count predicate-fact) => 2)
        (check (higher-order-fact-operand-count search-fact) => 2)
        (check (higher-order-fact-operand-count fold-fact) => 3)
        (check (higher-order-fact-operand-count cut-fact) => 3)
        (check (higher-order-fact-operand-count for-fold-fact) => 3)
        (check (higher-order-fact-operand-count autocurry-fact) => 2)
        (check (higher-order-fact-operand-count pipeline-fact) => 3)
        (check (higher-order-fact-operand-count rcompose-fact) => 2)
        (check (higher-order-fact-operand-count syntax-helper-fact) => 2)
        (check (higher-order-fact-operand-count generator-fact) => 1)
        (check (higher-order-fact-operand-count generator-thread-fact) => 1)
        (check (higher-order-fact-operand-count peekable-fact) => 1)
        (check (quality-facet-member? (higher-order-quality-facets case-lambda-fact)
                                      "case-lambda-optimization-boundary")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets map-fact)
                                      "expression-level-composition")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets fold-fact)
                                      "expression-level-composition")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets cut-fact)
                                      "combinator-composition")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets for-fold-fact)
                                      "builder-or-fold-combinator")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets autocurry-fact)
                                      "autocurry-application-semantics")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets pipeline-fact)
                                      "multi-value-composition")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets syntax-helper-fact)
                                      "syntax-helper-extraction")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets generator-thread-fact)
                                      "continuation-or-coroutine-boundary")
               => #t)
        (check (quality-facet-member? (higher-order-quality-facets peekable-fact)
                                      "stateful-protocol-wrapper")
               => #t)))
    (test-case "native reader captures control-flow syntax facts"
      (let* ((root (path-normalize "."))
             (file (parse-source-file root "t/fixtures/parser/control-flow.ss"))
             (facts (source-file-control-flow-forms file))
             (loop-fact
              (find-control-flow facts "loop" "manual-loop" "total"))
             (continuation-fact
              (find-control-flow facts "let/cc" "continuation-control" "first-or-stop"))
             (builder-fact
              (find-control-flow facts "with-list-builder" "builder-control" "safe-take"))
             (try-fact
              (find-control-flow facts "try" "protected-control" "safe-take"))
             (catch-fact
              (find-control-flow facts "catch" "protected-handler" "safe-take"))
             (finally-fact
              (find-control-flow facts "finally" "protected-handler" "safe-take"))
             (resource-fact
              (find-control-flow facts "call-with-output-string" "resource-scope" "capture-output"))
             (parameter-fact
              (find-control-flow facts "parameterize" "resource-scope" "capture-output"))
             (parameter-state-fact
              (find-control-flow facts "make-parameter" "parameter-state" "current-setting"))
             (cleanup-fact
              (find-control-flow facts "dynamic-wind" "cleanup-boundary" "with-dynamic"))
             (parameter-call-fact
              (find-control-flow facts "call-with-parameters" "parameter-state" "parameter-call"))
             (actor-fact
              (find-control-flow facts "spawn/name" "actor-control" "worker"))
             (coroutine-fact
              (find-control-flow facts "in-cothread" "coroutine-control" "coroutine-source"))
             (continuation-debug-fact
              (find-control-flow facts "continuation-capture" "continuation-control" "continuation-debug"))
             (total-contract
              (find-typed-contract (source-file-typed-contract-facts file) "total"))
             (repair-evidence
              (typed-contract-fact-repair-evidence total-contract)))
        (check (source-file-parse-error file) => #f)
        (check (>= (length facts) 8) => #t)
        (check (control-flow-fact-kind loop-fact) => "named-let")
        (check (control-flow-fact-binding-count loop-fact) => 2)
        (check (control-flow-fact-body-form-count loop-fact) => 1)
        (check (selector-owner? (control-flow-fact-selector loop-fact)
                                "t/fixtures/parser/control-flow.ss")
               => #t)
        (check (control-flow-fact-kind continuation-fact) => "let/cc")
        (check (control-flow-fact-kind builder-fact) => "with-list-builder")
        (check (control-flow-fact-kind try-fact) => "try")
        (check (control-flow-fact-kind catch-fact) => "catch")
        (check (control-flow-fact-kind finally-fact) => "finally")
        (check (control-flow-fact-kind resource-fact) => "call-with-output-string")
        (check (control-flow-fact-kind parameter-fact) => "parameterize")
        (check (control-flow-fact-kind parameter-state-fact) => "make-parameter")
        (check (control-flow-fact-kind cleanup-fact) => "dynamic-wind")
        (check (control-flow-fact-kind parameter-call-fact) => "call-with-parameters")
        (check (control-flow-fact-kind actor-fact) => "spawn/name")
        (check (control-flow-fact-kind coroutine-fact) => "in-cothread")
        (check (control-flow-fact-kind continuation-debug-fact) => "continuation-capture")
        (check (quality-facet-member? (control-flow-quality-facets cleanup-fact)
                                      "dynamic-cleanup-boundary")
               => #t)
        (check (quality-facet-member? (control-flow-quality-facets actor-fact)
                                      "actor-continuation-diagnostics")
               => #t)
        (check (quality-facet-member? (control-flow-quality-facets coroutine-fact)
                                      "generator-control-inversion")
               => #t)
        (check (quality-facet-member? (control-flow-quality-facets continuation-debug-fact)
                                      "continuation-capture-boundary")
               => #t)
        (check (not (not (member "manual-loop-drift"
                                  (typed-contract-fact-quality-facets total-contract))))
               => #t)
        (check (not (not (member "combinator-candidate"
                                  (typed-contract-fact-quality-facets total-contract))))
               => #t)
        (check (hash-get repair-evidence 'factSource) => "native-parser")
        (check (not (not (member "replace-manual-loop-with-higher-order-combinator-when-no-state-witness"
                                  (hash-get repair-evidence 'allowedMoves))))
               => #t)))
    (test-case "native reader captures @method POO dispatch facts"
      (let* ((root (path-normalize ".run/parser-poo-method-shapes"))
             (source-dir (string-append root "/src"))
             (source-path (string-append source-dir "/methods.ss")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-dir)
        (write-text source-path
                    ";;; -*- Gerbil -*-\n(package: sample/poo-method)\n(import :clan/poo/mop)\n(.defgeneric (order-discount Order amount))\n(defmethod (@method order-discount Order) (lambda (self amount) amount))\n(defmethod (:render (widget <Widget>) (ctx <Ctx>)) ctx)\n")
        (let* ((file (parse-source-file root "src/methods.ss"))
               (forms (source-file-poo-forms file))
               (generic (car forms))
               (method (cadr forms))
               (multi (caddr forms)))
          (check (map definition-name (source-file-definitions file))
                 => ["order-discount" "order-discount" ":render"])
          (check (poo-form-fact-role generic) => "generic")
          (check (poo-form-fact-name method) => "order-discount")
          (check (poo-form-fact-generic method) => "order-discount")
          (check (poo-form-fact-receiver method) => #f)
          (check (poo-form-fact-receiver-type method) => "Order")
          (check (poo-form-fact-specializers method) => ["Order"])
          (check (poo-form-fact-specializer-types method) => ["Order"])
          (check (poo-form-fact-specializers multi)
                 => ["widget:<Widget>" "ctx:<Ctx>"])
          (check (poo-form-fact-specializer-types multi)
                 => ["<Widget>" "<Ctx>"]))))
    (test-case "native reader captures local literal binding argument types"
      (let* ((root (path-normalize ".run/parser-local-literal-binding"))
             (source-dir (string-append root "/src"))
             (source-path (string-append source-dir "/main.ss")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-dir)
        (write-text source-path
                    "(package: sample/local-literal)\n(def (use-let)\n  (let ((value \"ok\") (bad 10))\n    (needs-string value)\n    (needs-string bad)))\n")
        (let* ((file (parse-source-file root "src/main.ss"))
               (calls (filter (lambda (call)
                                 (equal? (call-fact-callee call) "needs-string"))
                               (source-file-calls file)))
               (value-call (find-call-with-argument calls "value"))
               (bad-call (find-call-with-argument calls "bad")))
          (check (length calls) => 2)
          (check (call-fact-argument-types value-call) => ["string"])
          (check (call-fact-argument-types bad-call) => ["number"])
          (check (map call-fact-caller calls) => ["use-let" "use-let"]))))
    (test-case "native reader propagates sequential local alias argument types"
      (let* ((root (path-normalize ".run/parser-local-alias-binding"))
             (source-dir (string-append root "/src"))
             (source-path (string-append source-dir "/main.ss")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-dir)
        (write-text source-path
                    "(package: sample/local-alias)\n(def (use-let-star)\n  (let* ((star-value \"ok\")\n         (star-alias star-value)\n         (bad 10)\n         (bad-alias bad))\n    (needs-string star-alias)\n    (needs-string bad-alias)))\n(def (use-let)\n  (let ((plain-value \"ok\")\n        (plain-alias plain-value))\n    (needs-string plain-alias)))\n")
        (let* ((file (parse-source-file root "src/main.ss"))
               (calls (filter (lambda (call)
                                 (equal? (call-fact-callee call) "needs-string"))
                               (source-file-calls file)))
               (star-alias-call (find-call-with-argument calls "star-alias"))
               (bad-alias-call (find-call-with-argument calls "bad-alias"))
               (plain-alias-call (find-call-with-argument calls "plain-alias")))
          (check (length calls) => 3)
          (check (call-fact-argument-types star-alias-call) => ["string"])
          (check (call-fact-argument-types bad-alias-call) => ["number"])
          (check (call-fact-argument-types plain-alias-call) => [#f]))))
    (test-case "native reader tolerates malformed let forms"
      (let* ((root (path-normalize ".run/parser-malformed-let"))
             (source-dir (string-append root "/src"))
             (source-path (string-append source-dir "/main.ss")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-dir)
        (write-text source-path "(package: sample/main)\n(def answer (let))\n(define)\n")
        (let (file (parse-source-file root "src/main.ss"))
          (check (source-file-parse-error file) => #f)
          (check (map definition-name (source-file-definitions file))
                 => ["answer"])
          (check (source-file-calls file) => '()))))
    (test-case "project collection ignores tree-sitter query files"
      (let* ((root (path-normalize ".run/parser-tree-sitter-ignore"))
             (source-dir (string-append root "/src"))
             (query-dir (string-append root "/tree-sitter/tree-sitter-scheme/queries"))
             (source-path (string-append source-dir "/main.ss"))
             (query-path (string-append query-dir "/locals.scm")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-dir)
        (ensure-dir (string-append root "/tree-sitter"))
        (ensure-dir (string-append root "/tree-sitter/tree-sitter-scheme"))
        (ensure-dir query-dir)
        (write-text source-path "(package: sample/main)\n(def answer 42)\n")
        (write-text query-path "((identifier) @local.definition)\n")
        (check (map source-file-path (project-index-files (collect-project root)))
               => ["src/main.ss"])))
    (test-case "project collection captures gerbil package dependencies"
      (let* ((root (path-normalize ".run/parser-package"))
             (source-dir (string-append root "/src"))
             (package-path (string-append root "/gerbil.pkg"))
             (source-path (string-append source-dir "/main.ss")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-dir)
        (write-text package-path
                    "(package: clan/poo\n depend: (\"git.cons.io/mighty-gerbils/gerbil-utils\"))\n")
        (write-text source-path "(package: clan/poo/main)\n(def answer 42)\n")
        (let (package (project-index-package (collect-project root)))
          (check (project-package-path package) => "gerbil.pkg")
          (check (project-package-name package) => "clan/poo")
          (check (project-package-manager package) => "gxpkg")
          (check (project-package-dependencies package)
                 => ["git.cons.io/mighty-gerbils/gerbil-utils"]))))
    (test-case "project package configures source scope"
      (let* ((root (path-normalize ".run/parser-source-scope"))
             (lib-dir (string-append root "/lib"))
             (ignored-dir (string-append root "/scratch"))
             (package-path (string-append root "/gerbil.pkg"))
             (build-path (string-append root "/build.ss"))
             (lib-path (string-append lib-dir "/main.ss"))
             (ignored-path (string-append ignored-dir "/ignored.ss"))
             (flat-path (string-append root "/flat.ss")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir lib-dir)
        (ensure-dir ignored-dir)
        (write-text package-path
                    "(package: sample/scope\n  policy: ((source-scope roots: (\"lib\" \".\") exclude-directories: (\"scratch\") runtime-roots: (\"lib\") explanation: \"The project keeps runtime modules in lib and a small root entry.\")))\n")
        (write-text build-path ";;; -*- Gerbil -*-\n(defbuild-script '(\"lib/main\"))\n")
        (write-text lib-path "(package: sample/scope/main)\n(def answer 42)\n")
        (write-text ignored-path "(package: sample/scope/ignored)\n(def ignored 0)\n")
        (write-text flat-path "(package: sample/scope/flat)\n(def flat 1)\n")
        (let* ((index (collect-project root))
               (package (project-index-package index))
               (scope (project-package-source-scope-policy package)))
          (check (map source-file-path (project-index-files index))
                 => ["build.ss" "flat.ss" "gerbil.pkg" "lib/main.ss"])
          (check (source-scope-policy-roots scope) => ["lib" "."])
          (check (source-scope-policy-runtime-roots scope) => ["lib"])
          (check (source-scope-policy-exclude-directories scope) => ["scratch"]))))
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
          (check (hash-get extension 'package) => "sample/app"))))))
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

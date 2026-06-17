;;; -*- Gerbil -*-
(import :std/test
        :extensions/facade
        :parser/facade
        :protocol/json
        :std/srfi/13)
(export parser-test-part-8)

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
;; PredicateFamilyFact <- (List PredicateFamilyFact) String
(def (find-predicate-family facts subject)
  (find (lambda (fact)
          (equal? (predicate-family-fact-subject fact) subject))
        facts))
;; FieldAccessPatternFact <- (List FieldAccessPatternFact) String
(def (find-field-access-pattern facts field-key)
  (find (lambda (fact)
          (equal? (field-access-pattern-fact-field-key fact) field-key))
        facts))
;; BooleanConditionFact <- (List BooleanConditionFact) String
(def (find-boolean-condition facts caller)
  (find (lambda (fact)
          (equal? (boolean-condition-fact-caller fact) caller))
        facts))
;; LoopDriverFact <- (List LoopDriverFact) String
(def (find-loop-driver facts caller)
  (find (lambda (fact)
          (equal? (loop-driver-fact-caller fact) caller))
        facts))
;; FunctionQualityProfile <- (List FunctionQualityProfile) String
(def (find-function-quality-profile profiles name)
  (find (lambda (profile)
          (equal? (function-quality-profile-name profile) name))
        profiles))
;; PooFormFact <- (List PooFormFact) String
(def (find-poo-form facts name)
  (find (lambda (fact)
          (equal? (poo-form-fact-name fact) name))
        facts))
;; PooFormFact <- (List PooFormFact) String String
(def (find-poo-form-role facts name role)
  (find (lambda (fact)
          (and (equal? (poo-form-fact-name fact) name)
               (equal? (poo-form-fact-role fact) role)))
        facts))
;; ParsedData
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
;; TestSuite
(def parser-test-part-8
  (test-suite "gerbil scheme harness parser part 8"
    (test-case "source path class owns build policy scope"
          (check (source-path-class "gerbil.pkg") => "config")
          (check (source-path-class "build.ss") => "package-build")
          (check (source-path-class "build-support/provider-cli.ss")
                 => "build-support-runtime")
          (check (source-path-class "src/main.ss") => "runtime-source"))
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

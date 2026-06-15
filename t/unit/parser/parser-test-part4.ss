;;; -*- Gerbil -*-
(import :std/test
        :extensions/facade
        :parser/facade
        :protocol/json
        :std/srfi/13)
(export parser-test-part-4)

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
(def parser-test-part-4
  (test-suite "gerbil scheme harness parser part 4"
    (test-case "native reader captures defgeneric POO option facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-defgeneric.ss"))
                 (forms (source-file-poo-forms file))
                 (location (find-poo-form forms "location"))
                 (factory (find-poo-form forms "factory")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["location" "factory"])
            (check (map poo-form-fact-role forms) => ["generic" "generic"])
            (check (poo-form-fact-generic location) => "location")
            (check (poo-form-fact-options location)
                   => ["slot:location" "from:type" "default:"])
            (check (poo-form-fact-generic factory) => "factory")
            (check (poo-form-fact-options factory)
                   => ["compute-default:"])))
    (test-case "native reader classifies POO object slot syntax"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-object-slots.ss"))
                 (forms (source-file-poo-forms file))
                 (point (find-poo-form forms "point")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["base" "point"])
            (check (poo-form-fact-role point) => "object")
            (check (poo-form-fact-supers point) => ["base"])
            (check (poo-form-fact-slots point)
                   => ["x" "y" "total" "level" "child" "label" "greeting"])
            (check (poo-form-fact-options point)
                   => ["slot:x:lexical-constant"
                       "slot:y:self-computed"
                       "slot:total:self-computed"
                       "slot:level:inherited-computed"
                       "slot:child:mixin-override"
                       "slot:label:default"
                       "slot:greeting:inherited-computed"])))
    (test-case "JSON projection exposes POO object slot syntax facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-object-slots.ss"))
                 (packet (source-file-json file))
                 (forms (hash-get packet 'pooForms))
                 (point (find (lambda (form)
                                (equal? (hash-get form 'name) "point"))
                              forms)))
            (check (hash-get point 'role) => "object")
            (check (hash-get point 'supers) => ["base"])
            (check (hash-get point 'slots)
                   => ["x" "y" "total" "level" "child" "label" "greeting"])
            (check (hash-get point 'options)
                   => ["slot:x:lexical-constant"
                       "slot:y:self-computed"
                       "slot:total:self-computed"
                       "slot:level:inherited-computed"
                       "slot:child:mixin-override"
                       "slot:label:default"
                       "slot:greeting:inherited-computed"])))
    (test-case "native reader captures runtime module sugar definitions"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/runtime-module-sugar.ss"))
                 (macros (source-file-macros file))
                 (only-in (find-macro macros "only-in"))
                 (except-out (find-macro macros "except-out"))
                 (for-syntax (find-macro macros "for-syntax")))
            (check (source-file-parse-error file) => #f)
            (check (source-file-prelude file) => ":<root>")
            (check (source-file-package file) => "sample/runtime-module-sugar")
            (check (map definition-name (source-file-definitions file))
                   => ["only-in" "except-out" "for-syntax"])
            (check (map definition-kind (source-file-definitions file))
                   => ["defsyntax-for-import"
                       "defsyntax-for-export"
                       "defsyntax-for-import-export"])
            (check (map definition-formals (source-file-definitions file))
                   => [["stx"] ["stx"] ["stx"]])
            (check (map macro-fact-phase macros)
                   => ["import" "export" "import-export"])
            (check (macro-fact-kind only-in) => "defsyntax-for-import")
            (check (macro-fact-kind except-out) => "defsyntax-for-export")
            (check (macro-fact-kind for-syntax) => "defsyntax-for-import-export")
            (check (quality-facet-member? (macro-fact-quality-facets only-in)
                                          "syntax-case-transformer")
                   => #t)))))

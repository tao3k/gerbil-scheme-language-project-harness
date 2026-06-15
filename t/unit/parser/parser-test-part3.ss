;;; -*- Gerbil -*-
(import :std/test
        :extensions/facade
        :parser/facade
        :protocol/json
        :std/srfi/13)
(export parser-test-part-3)

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
(def parser-test-part-3
  (test-suite "gerbil scheme harness parser part 3"
    (test-case "native reader captures rationaldict adapter POO facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-rationaldict-adapter.ss"))
                 (forms (source-file-poo-forms file))
                 (dict (find-poo-form forms "RationalDict."))
                 (set (find-poo-form forms "RationalSet")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms)
                   => ["RationalDict." "RationalSet"])
            (check (poo-form-fact-supers dict) => ["methods.table"])
            (check (not (not (member "Key:" (poo-form-fact-slots dict))))
                   => #t)
            (check (not (not (member ".key?:"
                                      (poo-form-fact-slots dict))))
                   => #t)
            (check (not (not (member ".sexp<-:"
                                      (poo-form-fact-slots dict))))
                   => #t)
            (check (poo-form-fact-supers set) => ["Set<-Table."])
            (check (not (not (member "Table:"
                                      (poo-form-fact-slots set))))
                   => #t)
            (check (not (not (member ".min-elt:"
                                      (poo-form-fact-slots set))))
                   => #t)))
    (test-case "native reader captures POO type validation facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-type-validation.ss"))
                 (forms (source-file-poo-forms file))
                 (email (find-poo-form forms "EmailAddress."))
                 (positive-list (find-poo-form forms "PositiveList."))
                 (validation-call
                  (find (lambda (call)
                          (equal? (call-fact-callee call) "raise-type-error"))
                        (source-file-calls file))))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["EmailAddress." "PositiveList."])
            (check (map poo-form-fact-role forms) => ["type" "type"])
            (check (poo-form-fact-supers email) => ["String."])
            (check (not (not (member ".validate:" (poo-form-fact-slots email))))
                   => #t)
            (check (not (not (member ".sexp<-:" (poo-form-fact-slots email))))
                   => #t)
            (check (poo-form-fact-supers positive-list) => ["List."])
            (check (not (not (member "Elt:" (poo-form-fact-slots positive-list))))
                   => #t)
            (check (not (not (member ".validate:"
                                      (poo-form-fact-slots positive-list))))
                   => #t)
            (check (call-fact-callee validation-call) => "raise-type-error")))
    (test-case "native reader captures POO trace debug facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-trace-debug.ss"))
                 (forms (source-file-poo-forms file))
                 (trace-probe (find-poo-form forms "trace-probe"))
                 (print-method (find-poo-form-role forms ":pr" "method"))
                 (write-method (find-poo-form-role forms ":wr" "method"))
                 (callees (map call-fact-callee (source-file-calls file))))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms)
                   => ["base" "trace-probe" "trace-probe" ":pr" ":wr" ":pr" ":wr"])
            (check (map poo-form-fact-role forms)
                   => ["object" "object" "protocol" "generic" "generic" "method" "method"])
            (check (poo-form-fact-role trace-probe) => "object")
            (check (poo-form-fact-supers trace-probe) => ["base"])
            (check (poo-form-fact-slots trace-probe) => ["value" "runner" "debug"])
            (check (poo-form-fact-options trace-probe)
                   => ["slot:value:inherited-computed"
                       "slot:runner:self-computed"
                       "slot:debug:self-computed"])
            (check (poo-form-fact-specializers print-method) => ["trace-probe"])
            (check (poo-form-fact-specializer-types print-method) => ["trace-probe"])
            (check (poo-form-fact-specializers write-method) => ["trace-probe"])
            (check (not (not (member "trace-inherited-slot" callees))) => #t)
            (check (not (not (member "traced-function" callees))) => #t)
            (check (not (not (member "trace-poo" callees))) => #t)))
    (test-case "native reader captures POO multi-dispatch method facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-method-dispatch.ss"))
                 (forms (source-file-poo-forms file))
                 (distance (find-poo-form forms "distance"))
                 (intersect (find-poo-form forms ":intersect"))
                 (methods (filter (lambda (form)
                                    (equal? (poo-form-fact-role form) "method"))
                                  forms))
                 (distance-method (car methods))
                 (intersect-method (cadr methods)))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms)
                   => ["distance" ":intersect" "Point" "<Line>" "<Circle>" "<Ctx>" "distance" ":intersect"])
            (check (map poo-form-fact-role forms)
                   => ["generic" "generic" "protocol" "protocol" "protocol" "protocol" "method" "method"])
            (check (poo-form-fact-generic distance) => "distance")
            (check (poo-form-fact-generic intersect) => ":intersect")
            (check (poo-form-fact-generic distance-method) => "distance")
            (check (poo-form-fact-specializers distance-method)
                   => ["Point" "Point"])
            (check (poo-form-fact-specializer-types distance-method)
                   => ["Point" "Point"])
            (check (poo-form-fact-generic intersect-method) => ":intersect")
            (check (poo-form-fact-receiver intersect-method) => "line")
            (check (poo-form-fact-receiver-type intersect-method) => "<Line>")
            (check (poo-form-fact-specializers intersect-method)
                   => ["line:<Line>" "circle:<Circle>" "ctx:<Ctx>"])
            (check (poo-form-fact-specializer-types intersect-method)
                   => ["<Line>" "<Circle>" "<Ctx>"])))))

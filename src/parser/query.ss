;;; -*- Gerbil -*-
;;; Query helpers over parser-owned project facts.

(import :parser/facade
        :support/list
        :std/sort
        :std/srfi/13)

(export matching-definitions
        ranked-files
        ranked-query-files)
;;; Boundary:
;;; - matching-definitions composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Definition) <- (List Definition) (List Definition)
(def (matching-definitions definitions terms)
  (if (null? terms)
    definitions
    (filter
     (lambda (defn)
       (ormap (lambda (term)
                (string-contains (string-downcase (definition-name defn))
                                 (string-downcase term)))
              terms))
     definitions)))
;;; Boundary:
;;; - ranked-files composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- ProjectIndex
(def (ranked-files index)
  (sort (project-index-files index)
        (lambda (a b)
          (> (length (source-file-definitions a))
             (length (source-file-definitions b))))))
;;; Boundary:
;;; - ranked-query-files composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- ProjectIndex Query
(def (ranked-query-files index query)
  (let* ((terms (query-terms query))
         (scored
          (filter-map
           (lambda (file)
             (let (score (source-file-query-score file terms))
               (and (> score 0) (cons file score))))
           (project-index-files index))))
    (map car
         (sort scored
               (lambda (left right)
                 (ranked-query-file>? (car left) (cdr left)
                                      (car right) (cdr right)))))))
;; Boolean <- Left LeftScore Right RightScore
(def (ranked-query-file>? left left-score right right-score)
  (cond
   ((> left-score right-score) #t)
   ((< left-score right-score) #f)
   ((> (length (source-file-definitions left))
       (length (source-file-definitions right))) #t)
   ((< (length (source-file-definitions left))
       (length (source-file-definitions right))) #f)
   (else (string<? (source-file-path left) (source-file-path right)))))
;;; Invariant:
;;; - source-file-query-score owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- SourceFile (List SourceFile)
(def (source-file-query-score file terms)
  (let (haystack (string-downcase (source-file-query-haystack file)))
    (length (filter (cut string-contains haystack <>)
                    terms))))
;; SourceFileQueryHaystack <- SourceFile
(def (source-file-query-haystack file)
  (join (source-file-query-terms file) " "))
;;; Boundary:
;;; - source-file-query-terms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- SourceFile
(def (source-file-query-terms file)
  (filter searchable-term?
          (append
           [(source-file-path file)
            (source-file-package file)
            (source-file-prelude file)
            (source-file-namespace file)]
           (source-file-imports file)
           (source-file-exports file)
           (source-file-includes file)
           (append-map* definition-query-terms
                        (source-file-definitions file))
           (append-map* top-form-query-terms
                        (source-file-forms file))
           (append-map* module-import-query-terms
                        (source-file-module-imports file))
           (append-map* macro-query-terms
                        (source-file-macros file))
           (append-map* binding-query-terms
                        (source-file-bindings file))
           (append-map* poo-query-terms
                        (source-file-poo-forms file))
           (append-map* higher-order-query-terms
                        (source-file-higher-order-forms file))
           (append-map* control-flow-query-terms
                        (source-file-control-flow-forms file))
           (append-map* call-query-terms
                        (source-file-calls file)))))
;; Integer <- Definition
(def (definition-query-terms defn)
  [(definition-name defn)
   (definition-kind defn)
   (definition-selector defn)])
;; Integer <- Form
(def (top-form-query-terms form)
  [(top-form-head form)
   (top-form-kind form)
   (top-form-selector form)])
;; Integer <- String
(def (module-import-query-terms import)
  (append ["import" "module-import"
           (module-import-fact-module import)
           (module-import-fact-phase import)
           (module-import-fact-modifier import)
           (module-import-fact-alias import)
           (module-import-fact-selector import)]
          (module-import-fact-symbols import)))
;; Integer <- Macro
(def (macro-query-terms macro)
  ["macro"
   (macro-fact-name macro)
   (macro-fact-kind macro)
   (macro-fact-transformer macro)
   (macro-fact-phase macro)
   (macro-fact-selector macro)])
;; Integer <- Binding
(def (binding-query-terms binding)
  ["binding"
   (binding-fact-name binding)
   (binding-fact-kind binding)
   (binding-fact-scope binding)
   (binding-fact-value-type binding)
   (binding-fact-selector binding)])
;; (List SearchTerm) <- PooFormFact
(def (poo-query-terms fact)
  (append ["poo"
           "object-system"
           (poo-form-fact-name fact)
           (poo-form-fact-kind fact)
           (poo-form-fact-role fact)
           (poo-form-fact-generic fact)
           (poo-form-fact-receiver fact)
           (poo-form-fact-receiver-type fact)
           (poo-form-fact-selector fact)]
          (poo-form-fact-supers fact)
          (poo-form-fact-slots fact)
          (poo-form-fact-options fact)
          (poo-form-fact-specializers fact)
          (poo-form-fact-specializer-types fact)))
;; (List SearchTerm) <- HigherOrderFact
(def (higher-order-query-terms fact)
  ["higher-order"
   (higher-order-fact-name fact)
   (higher-order-fact-kind fact)
   (higher-order-fact-role fact)
   (higher-order-fact-caller fact)
   (higher-order-fact-selector fact)])
;; Integer <- ControlFlowFact
(def (control-flow-query-terms fact)
  ["control-flow"
   (control-flow-fact-name fact)
   (control-flow-fact-kind fact)
   (control-flow-fact-role fact)
   (control-flow-fact-caller fact)
   (control-flow-fact-selector fact)])
;;; Boundary:
;;; - call-query-terms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- CallFact
(def (call-query-terms call)
  (append ["call"
           (call-fact-callee call)
           (call-fact-caller call)
           (call-fact-selector call)]
          (filter searchable-term? (call-fact-argument-types call))))
;;; Boundary:
;;; - query-terms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- Query
(def (query-terms query)
  (map string-downcase
       (filter searchable-term? (split-query query))))
;;; Invariant:
;;; - split-query owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; SplitQuery <- Query
(def (split-query query)
  (string-tokenize query))
;; Boolean <- Char
(def (query-separator? char)
  (or (char=? char #\space)
      (char=? char #\tab)
      (char=? char #\newline)
      (char=? char #\return)
      (char=? char #\|)))
;;; Boundary:
;;; - append-map* composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- (YY <- XX) Values
(def (append-map* proc values)
  (apply append (map proc values)))
;; Boolean <- SearchTerm
(def (searchable-term? value)
  (and value
       (string? value)
       (> (string-length value) 0)))

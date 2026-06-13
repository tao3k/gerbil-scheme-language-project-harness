;;; -*- Gerbil -*-
;;; Query helpers over parser-owned project facts.

(import :parser/facade
        :support/list
        :std/sort
        :std/srfi/13)

(export matching-definitions
        ranked-files
        ranked-query-files)

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

(def (ranked-files index)
  (sort (project-index-files index)
        (lambda (a b)
          (> (length (source-file-definitions a))
             (length (source-file-definitions b))))))

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

(def (ranked-query-file>? left left-score right right-score)
  (cond
   ((> left-score right-score) #t)
   ((< left-score right-score) #f)
   ((> (length (source-file-definitions left))
       (length (source-file-definitions right))) #t)
   ((< (length (source-file-definitions left))
       (length (source-file-definitions right))) #f)
   (else (string<? (source-file-path left) (source-file-path right)))))

(def (source-file-query-score file terms)
  (let (haystack (string-downcase (source-file-query-haystack file)))
    (let lp ((rest terms) (score 0))
      (match rest
        ([term . more]
         (lp more
             (if (string-contains haystack term)
               (+ score 1)
               score)))
        (else score)))))

(def (source-file-query-haystack file)
  (join (source-file-query-terms file) " "))

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

(def (definition-query-terms defn)
  [(definition-name defn)
   (definition-kind defn)
   (definition-selector defn)])

(def (top-form-query-terms form)
  [(top-form-head form)
   (top-form-kind form)
   (top-form-selector form)])

(def (module-import-query-terms import)
  (append ["import" "module-import"
           (module-import-fact-module import)
           (module-import-fact-phase import)
           (module-import-fact-modifier import)
           (module-import-fact-alias import)
           (module-import-fact-selector import)]
          (module-import-fact-symbols import)))

(def (macro-query-terms macro)
  ["macro"
   (macro-fact-name macro)
   (macro-fact-kind macro)
   (macro-fact-transformer macro)
   (macro-fact-phase macro)
   (macro-fact-selector macro)])

(def (binding-query-terms binding)
  ["binding"
   (binding-fact-name binding)
   (binding-fact-kind binding)
   (binding-fact-scope binding)
   (binding-fact-value-type binding)
   (binding-fact-selector binding)])

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

(def (higher-order-query-terms fact)
  ["higher-order"
   (higher-order-fact-name fact)
   (higher-order-fact-kind fact)
   (higher-order-fact-role fact)
   (higher-order-fact-caller fact)
   (higher-order-fact-selector fact)])

(def (control-flow-query-terms fact)
  ["control-flow"
   (control-flow-fact-name fact)
   (control-flow-fact-kind fact)
   (control-flow-fact-role fact)
   (control-flow-fact-caller fact)
   (control-flow-fact-selector fact)])

(def (call-query-terms call)
  (append ["call"
           (call-fact-callee call)
           (call-fact-caller call)
           (call-fact-selector call)]
          (filter searchable-term? (call-fact-argument-types call))))

(def (query-terms query)
  (map string-downcase
       (filter searchable-term? (split-query query))))

(def (split-query query)
  (let (len (string-length query))
    (let lp ((i 0) (start #f) (out '()))
      (cond
       ((>= i len)
        (reverse
         (if start
           (cons (substring query start i) out)
           out)))
       ((query-separator? (string-ref query i))
        (lp (+ i 1)
            #f
            (if start
              (cons (substring query start i) out)
              out)))
       (start (lp (+ i 1) start out))
       (else (lp (+ i 1) i out))))))

(def (query-separator? char)
  (or (char=? char #\space)
      (char=? char #\tab)
      (char=? char #\newline)
      (char=? char #\return)
      (char=? char #\|)))

(def (append-map* proc values)
  (apply append (map proc values)))

(def (searchable-term? value)
  (and value
       (string? value)
       (> (string-length value) 0)))

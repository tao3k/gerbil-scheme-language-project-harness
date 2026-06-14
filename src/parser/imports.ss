;;; -*- Gerbil -*-
;;; Parser-owned import facts for Gerbil module forms.

(import :gerbil/expander
        :parser/model
        :parser/support
        :std/srfi/13)

(export module-import-facts-from-form)

;;; Boundary:
;;; - module-import-facts-from-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ModuleImportFactsFromForm <- Relpath Form
(def (module-import-facts-from-form relpath form)
  (filter-map (cut module-import-fact-from-stx relpath <>)
              (cdr (stx-list-items form))))

;; ModuleImportFactFromStx <- Relpath Item
(def (module-import-fact-from-stx relpath item)
  (let* ((datum (syntax->datum item))
         (loc (stx-source item))
         (module (module-ref-from-import-datum datum)))
    (and module
         (make-module-import-fact module
                                  (import-phase datum)
                                  (import-modifier datum)
                                  (import-alias datum)
                                  (import-symbols datum)
                                  relpath
                                  (source-start-line loc)
                                  (source-end-line loc)))))

;;; Boundary:
;;; Import wrappers can nest the module reference behind only-in/rename-in forms.
;;; The find combinator keeps that search declarative and returns only a module
;;; ref datum accepted by module-ref-datum?, never an arbitrary operand.
;; ModuleRefFromImportDatum <- Datum
(def (module-ref-from-import-datum datum)
  (cond
   ((module-ref-datum? datum) => values)
   ((pair? datum)
    (let (found (find module-ref-datum? (datum-list-items (cdr datum))))
      (and found (module-ref-datum? found))))
   (else #f)))

;; (Maybe String) <- Datum
(def (module-ref-datum? datum)
  (cond
   ((string? datum) datum)
   ((and (symbol? datum) (module-ref-symbol? datum)) (symbol->string datum))
   (else #f)))

;; Boolean <- Symbol
(def (module-ref-symbol? symbol)
  (string-prefix? ":" (symbol->string symbol)))

;; ImportModifier <- Datum
(def (import-modifier datum)
  (if (pair? datum)
    (datum->string (car datum))
    "direct"))

;; String <- Datum
(def (import-phase datum)
  (cond
   ((and (pair? datum) (eq? (car datum) 'for-syntax)) "syntax")
   ((and (pair? datum) (eq? (car datum) 'for-template)) "template")
   ((and (pair? datum) (eq? (car datum) 'phi:))
    (let (phase (safe-cadr datum))
      (if phase
        (string-append "phase:" (datum->string phase))
        "phase")))
   (else "runtime")))

;;; Boundary:
;;; - import-symbols composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- Datum
(def (import-symbols datum)
  (if (pair? datum)
    (dedupe
     (filter-map
      (lambda (item)
        (and (symbol? item)
             (not (import-control-symbol? item))
             (not (module-ref-symbol? item))
             (symbol->string item)))
      (flatten datum)))
    '()))

;; Boolean <- Symbol
(def (import-control-symbol? symbol)
  (member (symbol->string symbol)
          '("for-syntax" "only-in" "except-in" "rename-in" "rename-out"
            "prefix-in" "prefix:" "rename:" "phi:" "import:" "except-out"
            "for-template" "group-in" "only-out" "prefix-out" "group-out"
            "+1" "-1" "0")))

;; ImportAlias <- Datum
(def (import-alias datum)
  (and (pair? datum)
       (member (car datum) '(rename-in rename-out prefix-in))
       (let (symbols (import-symbols datum))
         (and (pair? symbols) (car symbols)))))

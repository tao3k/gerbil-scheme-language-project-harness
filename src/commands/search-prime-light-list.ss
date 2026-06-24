;;; -*- Gerbil -*-
;;; Dependency-light list and datum helpers for the search prime launcher.

(import :gerbil/gambit)

(export take-up-to
        last-item
        datum-list-items
        safe-cadr
        datum->string
        find
        filter-map
        filter-list
        any
        unique)

;; take-up-to
;;   : (forall (a) (-> (List a) Integer (List a)))
;;   | doc m%
;;       `take-up-to` returns at most `limit` values without failing on short
;;       input lists.
;;
;;       # Examples
;;
;;       ```scheme
;;       (take-up-to '(a b) 4)
;;       ;; => (a b)
;;       ```
;;     %
;;; Bounded list boundary:
;;; - The recursion stops on either input exhaustion or the preview limit.
;;; - Consing from the front preserves source order without an accumulator.
(def (take-up-to values limit)
  (if (or (null? values) (<= limit 0))
    '()
    (cons (car values)
          (take-up-to (cdr values) (- limit 1)))))

;; : (forall (a) (-> (List a) a))
(def (last-item values)
  (if (and (pair? values) (pair? (cdr values)))
    (last-item (cdr values))
    (car values)))

;; : (-> Obj (List Obj))
(def (datum-list-items obj)
  (if (pair? obj)
    (cons (car obj) (datum-list-items (cdr obj)))
    '()))

;; : (-> Obj (U #f Obj))
(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

;;; Datum rendering boundary:
;;; - Package metadata scalars are normalized to strings for packet fields.
;;; - Non-scalar datums use display output only at this metadata edge.
;; : (-> Obj (U #f String))
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   ((keyword? obj) (string-append (keyword->string obj) ":"))
   (else (call-with-output-string "" (cut display obj <>)))))

;;; Search predicate boundary:
;;; - Return the first matching value and leave ordering decisions to callers.
;;; - This local helper keeps the release launcher dependency-light.
;; : (forall (a) (-> (-> a Boolean) (List a) (U #f a)))
(def (find predicate values)
  (cond
   ((null? values) #f)
   ((predicate (car values)) (car values))
   (else (find predicate (cdr values)))))

;; filter-map
;;   : (forall (a b) (-> (-> a (U #f b)) (List a) (List b)))
;;   | doc m%
;;       `filter-map` applies a mapper and keeps truthy mapped values in source
;;       order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (filter-map (lambda (x) x) '(a #f b))
;;       ;; => (a b)
;;       ```
;;     %
;;; Projection boundary:
;;; - Mapper failure is represented by `#f`, not an exception.
;;; - The helper is local so the release launcher stays dependency-light.
(def (filter-map procedure values)
  (if (null? values)
    '()
    (let* ((value (procedure (car values)))
           (rest (filter-map procedure (cdr values))))
      (if value (cons value rest) rest))))

;; filter-list
;;   : (forall (a) (-> (-> a Boolean) (List a) (List a)))
;;   | doc m%
;;       `filter-list` keeps values whose predicate succeeds while preserving
;;       source order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (filter-list symbol? '(a "b"))
;;       ;; => (a)
;;       ```
;;     %
;;; Predicate boundary:
;;; - This local filter avoids pulling the full parser utility stack into the
;;;   release search-prime launcher.
(def (filter-list predicate values)
  (cond
   ((null? values) '())
   ((predicate (car values))
    (cons (car values) (filter-list predicate (cdr values))))
   (else (filter-list predicate (cdr values)))))

;;; Existential predicate boundary:
;;; - Stop at the first truthy predicate result.
;;; - This is the local list predicate used by extension/source checks.
;; : (forall (a) (-> (-> a Boolean) (List a) Boolean))
(def (any predicate values)
  (and (pair? values)
       (or (predicate (car values))
           (any predicate (cdr values)))))

;; unique
;;   : (-> (List String) (List String))
;;   | doc m%
;;       `unique` removes duplicate strings while preserving the first
;;       occurrence order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (unique '("src" "src" "t"))
;;       ;; => ("src" "t")
;;       ```
;;     %
;;; Stable dedupe boundary:
;;; - The recursive filter removes later duplicates of the current head.
;;; - Source-root previews stay deterministic without a mutable seen table.
(def (unique values)
  (if (null? values)
    '()
    (cons (car values)
          (unique
           (filter-list (lambda (value)
                          (not (equal? value (car values))))
                        (cdr values))))))

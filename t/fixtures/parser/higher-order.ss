;;; -*- Gerbil -*-
;;; Boundary:
;;; - Higher-order fixture contracts stay adjacent to each definition so parser evidence can prove style coverage.
;;; - Keep each transform expression-shaped to exercise combinator, generator, and syntax witnesses without broad prose.
(import :std/sugar
        :std/srfi/1
        (rename-in :std/misc/list (foldl fold-left)))
(export select names positives positive-names any-positive? first-positive total bump counted)
;; (List Item) <- Item
(def select
  (case-lambda
    (() '())
    ((x) [x])))
;; (List String) <- Widgets
(def (names widgets)
  (map (lambda (widget) (slot-ref widget 'name)) widgets))
;; (List PositiveNumber) <- (List Number)
(def (positives xs)
  (filter (lambda (n) (> n 0)) xs))
;; (List String) <- Widgets
(def (positive-names widgets)
  (filter-map (lambda (widget)
                (and (slot-ref widget 'positive?)
                     (slot-ref widget 'name)))
              widgets))
;; Boolean <- (List Number)
(def (any-positive? xs)
  (ormap (lambda (n) (> n 0)) xs))
;; PositiveNumber <- (List Number)
(def (first-positive xs)
  (find (lambda (n) (> n 0)) xs))
;; Integer <- (List Number)
(def (total xs)
  (fold-left (lambda (acc n) (+ acc n)) 0 xs))
;; Integer <- Integer
(def bump
  (cut + <> 1))
;; Integer <- (List Number)
(def (counted xs)
  (for/fold ((count 0)) ((item xs))
    (+ count 1)))
;; Integer <- Integer Integer
(defn (autocurried x y)
  (+ x y))
;; Integer <- Integer
(def (pipeline x)
  (!> x (cut + <> 1) (cut * <> 2)))
;; (Z <- X) <- (Y <- X) (Z <- Y)
(def (compose-values f g)
  (rcompose f g))
;; (List Syntax) <- (List Syntax)
(def (syntax-helper args)
  (stx-apply list args))
;; Generator <- ForEachProcedure
(def (generator-source for-each)
  (generating<-for-each for-each))
;; Generator <- ForEachProcedure
(def (generator-thread for-each)
  (generating<-cothread for-each))
;; (PeekableIterator Element) <- (Iterator Element)
(def (peekable it)
  (:peekable-iter it))

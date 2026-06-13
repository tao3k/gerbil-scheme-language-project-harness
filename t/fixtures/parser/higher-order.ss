;;; -*- Gerbil -*-
(import :std/sugar
        :std/srfi/1
        (rename-in :std/misc/list (foldl fold-left)))
(export select names positives positive-names any-positive? first-positive total bump counted)

(def select
  (case-lambda
    (() '())
    ((x) [x])))

(def (names widgets)
  (map (lambda (widget) (slot-ref widget 'name)) widgets))

(def (positives xs)
  (filter (lambda (n) (> n 0)) xs))

(def (positive-names widgets)
  (filter-map (lambda (widget)
                (and (slot-ref widget 'positive?)
                     (slot-ref widget 'name)))
              widgets))

(def (any-positive? xs)
  (ormap (lambda (n) (> n 0)) xs))

(def (first-positive xs)
  (find (lambda (n) (> n 0)) xs))

(def (total xs)
  (fold-left (lambda (acc n) (+ acc n)) 0 xs))

(def bump
  (cut + <> 1))

(def (counted xs)
  (for/fold ((count 0)) ((item xs))
    (+ count 1)))

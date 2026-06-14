;;; -*- Gerbil -*-
;;; Small list/string helpers for command adapters.

(export dedupe
        take*
        take-at-most
        map-indexed
        last
        join)
;;; Boundary:
;;; - dedupe composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Dedupe <- (List XX)
(def (dedupe xs)
  (let (state
        (foldl (lambda (item state)
                 (let ((seen (car state))
                       (out (cdr state)))
                   (if (member item seen)
                     state
                     (cons (cons item seen) (cons item out)))))
               (cons '() '())
               xs))
    (reverse (cdr state))))
;;; Boundary:
;;; - take* composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Take <- (List XX) N
(def (take* xs n)
  (let (state
        (foldl (lambda (item state)
                 (let ((remaining (car state))
                       (out (cdr state)))
                   (if (fx<= remaining 0)
                     state
                     (cons (fx1- remaining) (cons item out)))))
               (cons n '())
               xs))
    (reverse (cdr state))))
;; TakeAtMost <- (List XX) N
(def (take-at-most xs n)
  (take* xs n))
;;; Boundary:
;;; - map-indexed composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- (YY <- XX) (List XX)
(def (map-indexed proc xs)
  (let (state
        (foldl (lambda (item state)
                 (let ((rank (car state))
                       (out (cdr state)))
                   (cons (fx1+ rank) (cons (proc item rank) out))))
               (cons 1 '())
               xs))
    (reverse (cdr state))))
;; Last <- (List XX)
(def (last xs)
  (if (null? (cdr xs)) (car xs) (last (cdr xs))))
;;; Invariant:
;;; - join owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Join <- (List XX) Sep
(def (join xs sep)
  (match xs
    ([] "")
    ([x] x)
    ([x . rest] (string-append x sep (join rest sep)))))

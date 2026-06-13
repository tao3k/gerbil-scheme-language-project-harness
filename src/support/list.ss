;;; -*- Gerbil -*-
;;; Small list/string helpers for command adapters.

(export dedupe
        take*
        map-indexed
        last
        join)

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

(def (map-indexed proc xs)
  (let (state
        (foldl (lambda (item state)
                 (let ((rank (car state))
                       (out (cdr state)))
                   (cons (fx1+ rank) (cons (proc item rank) out))))
               (cons 1 '())
               xs))
    (reverse (cdr state))))

(def (last xs)
  (if (null? (cdr xs)) (car xs) (last (cdr xs))))

(def (join xs sep)
  (match xs
    ([] "")
    ([x] x)
    ([x . rest] (string-append x sep (join rest sep)))))

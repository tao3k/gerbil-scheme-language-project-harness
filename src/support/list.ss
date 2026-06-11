;;; -*- Gerbil -*-
;;; Small list/string helpers for command adapters.

(export dedupe
        take*
        last
        join)

(def (dedupe xs)
  (let lp ((rest xs) (seen '()) (out '()))
    (match rest
      ([] (reverse out))
      ([hd . tl]
       (if (member hd seen)
         (lp tl seen out)
         (lp tl (cons hd seen) (cons hd out)))))))

(def (take* xs n)
  (if (or (zero? n) (null? xs))
    '()
    (cons (car xs) (take* (cdr xs) (fx1- n)))))

(def (last xs)
  (if (null? (cdr xs)) (car xs) (last (cdr xs))))

(def (join xs sep)
  (match xs
    ([] "")
    ([x] x)
    ([x . rest] (string-append x sep (join rest sep)))))

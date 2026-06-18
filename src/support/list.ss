;;; -*- Gerbil -*-
;;; Small list/string helpers for command adapters.

(export dedupe
        take*
        take-at-most
        map-indexed
        last
        join)

;; dedupe
;;   : (forall (a)
;;       (-> (List a)
;;           (List a)))
;;   | doc m%
;;       `dedupe xs` returns `xs` with later duplicate values removed while
;;       preserving the first occurrence order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (dedupe '(a b a c b))
;;       ;; => (a b c)
;;       ```
;;     %
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

;; take*
;;   : (forall (a)
;;       (-> (List a)
;;           Integer
;;           (List a)))
;;   | doc m%
;;       `take* xs n` returns at most the first `n` elements of `xs`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (take* '(a b c) 2)
;;       ;; => (a b)
;;       ```
;;     %
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

;; take-at-most
;;   : (forall (a)
;;       (-> (List a)
;;           Integer
;;           (List a)))
;;   | doc m%
;;       `take-at-most xs n` delegates to `take*` for callers that read the
;;       operation as a bounded projection.
;;
;;       # Examples
;;
;;       ```scheme
;;       (take-at-most '(a b c) 4)
;;       ;; => (a b c)
;;       ```
;;     %
(def (take-at-most xs n)
  (take* xs n))

;; map-indexed
;;   : (forall (a b)
;;       (-> (-> a Integer b)
;;           (List a)
;;           (List b)))
;;   | doc m%
;;       `map-indexed proc xs` maps each element with its one-based index.
;;
;;       # Examples
;;
;;       ```scheme
;;       (map-indexed cons '(a b))
;;       ;; => ((a . 1) (b . 2))
;;       ```
;;     %
(def (map-indexed proc xs)
  (let (state
        (foldl (lambda (item state)
                 (let ((rank (car state))
                       (out (cdr state)))
                   (cons (fx1+ rank) (cons (proc item rank) out))))
               (cons 1 '())
               xs))
    (reverse (cdr state))))

;; last
;;   : (forall (a)
;;       (-> (List a)
;;           a))
;;   | requires (not (null? xs))
;;   | warning empty lists are a caller error
;;   | doc m%
;;       `last xs` returns the final element of a non-empty list.
;;
;;       # Examples
;;
;;       ```scheme
;;       (last '(a b c))
;;       ;; => c
;;       ```
;;     %
(def (last xs)
  (if (null? (cdr xs)) (car xs) (last (cdr xs))))

;; join
;;   : (-> (List String)
;;         String
;;         String)
;;   | doc m%
;;       `join xs sep` concatenates string elements with `sep` between each
;;       adjacent pair.
;;
;;       # Examples
;;
;;       ```scheme
;;       (join '("a" "b" "c") ",")
;;       ;; => "a,b,c"
;;       ```
;;     %
(def (join xs sep)
  (match xs
    ([] "")
    ([x] x)
    ([x . rest] (string-append x sep (join rest sep)))))

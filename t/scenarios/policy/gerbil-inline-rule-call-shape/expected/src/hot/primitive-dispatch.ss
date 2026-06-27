;;; -*- Gerbil -*-
;;; Expected: keep primitive calls lexical and direct so inline rules can see them.
(package: scenario/gerbil-inline-rule-call-shape/expected)
(import :gerbil/gambit)
(export count-small small?)

(def (small? value limit)
  (fx< value limit))

(def (count-small values limit)
  (let loop ((rest values)
             (count 0))
    (if (null? rest)
      count
      (let (next-count
            (if (small? (car rest) limit)
              (fx+ count 1)
              count))
        (loop (cdr rest) next-count)))))

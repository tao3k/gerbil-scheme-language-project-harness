;;; -*- Gerbil -*-
;;; Expected: use Gambit numeric lanes when the domain is fixed.
(package: scenario/gambit-fixnum-flonum-arithmetic-boundary/expected)
(import :gerbil/gambit)
(export sum-samples)

(def (sum-samples samples)
  (let loop ((rest samples)
             (count 0)
             (total 0.0))
    (if (null? rest)
      (cons count total)
      (loop (cdr rest)
            (fx+ count 1)
            (fl+ total (car rest))))))

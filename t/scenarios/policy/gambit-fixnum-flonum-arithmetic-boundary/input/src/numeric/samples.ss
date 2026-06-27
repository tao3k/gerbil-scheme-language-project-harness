;;; -*- Gerbil -*-
;;; Input: generic arithmetic in a telemetry hot path hides numeric intent.
(package: scenario/gambit-fixnum-flonum-arithmetic-boundary/input)
(export sum-samples)

(def (sum-samples samples)
  (let loop ((rest samples)
             (count 0)
             (total 0.0))
    (if (null? rest)
      (cons count total)
      (loop (cdr rest)
            (+ count 1)
            (+ total (car rest))))))

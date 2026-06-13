;;; -*- Gerbil -*-
;;; Small timing helpers for benchmark and snapshot code.

(import :gerbil/gambit)

(export monotonic-ms
        duration-ms
        average-duration-ms
        average-duration-micros
        duration-state)

(def (monotonic-ms)
  (inexact->exact (floor (* 1000.0 (##current-time-point)))))

(def (duration-ms start-ms end-ms)
  (- end-ms start-ms))

(def (average-duration-ms total-ms iterations)
  (quotient total-ms iterations))

(def (average-duration-micros total-ms iterations)
  (quotient (* total-ms 1000) iterations))

(def (duration-state value)
  (if (and (number? value) (>= value 0))
    "measured"
    "missing"))

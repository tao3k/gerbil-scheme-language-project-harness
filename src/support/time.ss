;;; -*- Gerbil -*-
;;; Small timing helpers for benchmark and snapshot code.

(import :gerbil/gambit)

(export monotonic-ms
        duration-ms
        monotonic-micros
        duration-micros
        average-duration-ms
        average-duration-micros
        duration-state)
;; Integer
(def (monotonic-ms)
  (inexact->exact (floor (* 1000.0 (##current-time-point)))))
;; : (-> StartMs EndMs Integer )
(def (duration-ms start-ms end-ms)
  (- end-ms start-ms))
;; Integer
(def (monotonic-micros)
  (inexact->exact (floor (* 1000000.0 (##current-time-point)))))
;; : (-> StartMicros EndMicros Integer )
(def (duration-micros start-micros end-micros)
  (- end-micros start-micros))
;; : (-> TotalMs Iterations Integer )
(def (average-duration-ms total-ms iterations)
  (quotient total-ms iterations))
;; : (-> TotalMs Iterations Integer )
(def (average-duration-micros total-ms iterations)
  (quotient (* total-ms 1000) iterations))
;; : (-> RawDuration DurationState )
(def (duration-state value)
  (if (and (number? value) (>= value 0))
    "measured"
    "missing"))

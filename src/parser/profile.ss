;;; -*- Gerbil -*-
;;; Parser profile helpers.

(import :gerbil/gambit
        :support/time
        (only-in :std/sort sort)
        (only-in :std/srfi/1 take))

(export profile-row
        timed-profile-value
        slowest-profile-rows
        optional-environment-variable
        collect-project-worker-count)

;; profile-row
;;   : (-> String Integer HashTable)
;;   | doc m%
;;       `profile-row name duration-ms` creates one JSON-ready timing row for
;;       a named parser phase.
;;       # Examples
;;       ```scheme
;;       (hash-get (profile-row "parse" 12) 'durationMs)
;;       ;; => 12
;;       ```
;;     %
(def (profile-row name duration-ms)
  (hash (name name)
        (durationMs duration-ms)))

;; timed-profile-value
;;   : (-> String Procedure (Values Value HashTable))
;;   | doc m%
;;       `timed-profile-value name thunk` returns values for the thunk result
;;       and timing row, keeping profiling tuples out of anonymous vectors.
;;     %
(def (timed-profile-value name thunk)
  (let (start (monotonic-ms))
    (let (value (thunk))
      (values value
              (profile-row name (duration-ms start (monotonic-ms)))))))

;;; Profile ranking boundary: timing rows are JSON-facing hash packets, so the
;;; comparator uses only `durationMs` and leaves later row fields out of the
;;; ordering contract.
;; slowest-profile-rows
;;   : (-> (List HashTable) Integer (List HashTable))
;;   | doc m%
;;       `slowest-profile-rows rows limit` returns the highest-duration rows
;;       while preserving the row packet shape.
;;     %
(def (slowest-profile-rows rows limit)
  (let* ((ordered (sort rows
                        (lambda (left right)
                          (> (hash-get left 'durationMs)
                             (hash-get right 'durationMs)))))
         (count (min limit (length ordered))))
    (take ordered count)))

;;; Environment boundary: optional tuning variables are configuration hints, so
;;; missing or unreadable environment state collapses to `#f` instead of
;;; turning parser startup into a runtime failure.
;; optional-environment-variable
;;   : (-> String (Or String False))
;;   | doc m%
;;       `optional-environment-variable name` returns an environment value when
;;       available and `#f` when the lookup is unavailable.
;;     %
(def (optional-environment-variable name)
  (with-catch
    (lambda (_) #f)
    (lambda () (getenv name))))

;; collect-project-worker-count
;;   : (-> Integer Integer)
;;   | doc m%
;;       `collect-project-worker-count file-count` caps parser worker count by
;;       file count, configured `GSLPH_COLLECT_CORES`, and host CPU count.
;;     %
(def (collect-project-worker-count file-count)
  (let* ((raw (optional-environment-variable "GSLPH_COLLECT_CORES"))
         (configured (and raw (string->number raw)))
         (cores (if (and configured
                         (integer? configured)
                         (> configured 0))
                  configured
                  (##cpu-count))))
    (max 1 (min file-count cores))))

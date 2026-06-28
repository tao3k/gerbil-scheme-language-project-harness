;;; -*- Gerbil -*-
;;; Dynamic state cleanup is owned by dynamic-wind.
(package: sample/runtime)
(export with-directory)

;; with-directory
;;   : (-> Path (-> Value) Value)
;;   | warning current-directory restoration is an unwind boundary
;;   | doc m%
;;       `with-directory` restores the previous directory even when `thunk`
;;       raises, aborts, or re-enters through continuation control.
;;     %
(def (with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))

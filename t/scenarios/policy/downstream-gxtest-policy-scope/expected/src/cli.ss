;;; -*- Gerbil -*-
;;; Boundary: this fixture module is the package-local source owner that gxtest
;;; policy must reach through unit test imports.
(export total)

;;; Boundary: keep CLI total as a pure fold so gxtest policy scope proves the
;;; imported source owner is clean without needing full-project fallback.
;; total
;;   : (-> (List Number) Number)
;;   | doc m%
;;       `total xs` sums CLI values with a pure fold boundary.
;;     %
(def (total xs)
  (foldl + 0 xs))

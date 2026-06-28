;;; -*- Gerbil -*-
;;; Manual dynamic state restore can skip cleanup on exceptions.
(package: sample/runtime)
(export with-directory)

;; with-directory
;;   : (-> Path (-> Value) Value)
;;   | warning current-directory must be restored even when thunk escapes
;;   | doc m%
;;       `with-directory` runs `thunk` while the process directory is changed.
;;     %
(def (with-directory directory thunk)
  (let (previous (current-directory))
    (current-directory directory)
    (let (result (thunk))
      (current-directory previous)
      result)))

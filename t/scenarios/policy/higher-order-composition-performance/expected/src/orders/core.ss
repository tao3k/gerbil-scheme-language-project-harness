;;; -*- Gerbil -*-
;;; Boundary:
;;; - Decoration stays a reusable function pipeline instead of wrapper lambda
;;;   scaffolding.
(package: sample/orders)
(import (only-in :clan/base compose cut))
(export decorate)

;; decorate
;;   : (-> String String (-> String String))
;;   | doc m%
;;       `decorate prefix suffix` builds one reusable text transform pipeline.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((decorate "[" "]") "paid")
;;       ;; => "[paid]"
;;       ```
;;     %
(def (decorate prefix suffix)
  (compose (cut string-append <> suffix)
           (cut string-append prefix <>)))

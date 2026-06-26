;;; -*- Gerbil -*-
;;; Widget update facade.
(package: sample/widgets)
(export update-widget)

;; : (-> Interface Contract Slot Get Set Modify Validate Widget)
(def (update-widget widget slot value)
  (let* ((current (hash-get widget slot))
         (next (if (and value
                        (not (equal? value "")))
                 value
                 current))
         (copy (hash-copy widget)))
    (hash-put! copy slot next)
    copy))

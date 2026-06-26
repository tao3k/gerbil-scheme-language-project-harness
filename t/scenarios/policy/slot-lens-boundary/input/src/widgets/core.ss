;;; -*- Gerbil -*-
;;; Widget facade.
(package: sample/widgets)
(export rename-widget)

;; : (-> Slot Lens Get Set Modify Validate Widget)
(def (rename-widget widget slot name)
  (let* ((current (hash-get widget slot))
         (next (if (and (string? name) (> (string-length name) 0))
                 name
                 current))
         (copy (hash-copy widget)))
    (hash-put! copy slot next)
    copy))

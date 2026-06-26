;;; -*- Gerbil -*-
;;; Installed executable root for gslph.

(import :checker/model
        :extensions/model
        :parser/model
        :policy/model
        :types/findings
        :types/model
        (rename-in :cli-launcher (main launcher-main)))
(export main)

;;; Install binary boundary:
;;; - The command graph remains dynamic so install/link stays small.
;;; - Struct/class model modules are statically loaded to avoid optimized
;;;   executable dynamic-load gaps around `make-class-predicate`.

;; : (-> Args Integer)
(def (main . args)
  (apply launcher-main args))

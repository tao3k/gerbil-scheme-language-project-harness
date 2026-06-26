;;; -*- Gerbil -*-
;;; Exception facade.
(package: sample/exceptions)

(import (only-in :std/sugar try catch))

(export run-checked)

;; : (-> Exception Continuation Handler Context Raise Outcome)
(def (run-checked thunk label)
  (try
   (thunk)
   (catch (e)
     (displayln (string-append "failed: " label))
     #f)))

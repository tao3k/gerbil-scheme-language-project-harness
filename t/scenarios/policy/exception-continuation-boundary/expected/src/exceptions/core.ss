;;; -*- Gerbil -*-
;;; Boundary:
;;; - Exception handling keeps diagnostics, context logging, and re-raise
;;;   behavior in local helpers instead of swallowing failures in the caller.
(package: sample/exceptions)

(import (only-in :std/sugar try catch))

(export run-checked)

;; exception-message
;;   : (-> Exception String)
;;   | doc m%
;;       `exception-message` keeps printable diagnostics local to the exception
;;       boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (exception-message exn)
;;       ;; => "exception"
;;       ```
;;     %
(def (exception-message e)
  (if (string? e) e "exception"))

;; log-exception-context
;;   : (-> String Exception Void)
;;   | doc m%
;;       `log-exception-context` owns the label-specific diagnostic side effect.
;;
;;       # Examples
;;
;;       ```scheme
;;       (log-exception-context "job" exn)
;;       ;; => void
;;       ```
;;     %
(def (log-exception-context label e)
  (displayln
   (string-append "failed: " label ": " (exception-message e))))

;; reraise-exception
;;   : (-> Exception Never)
;;   | doc m%
;;       `reraise-exception` preserves failure semantics after logging.
;;
;;       # Examples
;;
;;       ```scheme
;;       (reraise-exception exn)
;;       ;; => raises
;;       ```
;;     %
(def (reraise-exception e)
  (raise e))

;; call-with-exception-boundary
;;   : (-> String (-> Outcome) Outcome)
;;   | doc m%
;;       `call-with-exception-boundary` keeps the local exception-control path
;;       separate from the public operation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (call-with-exception-boundary "job" thunk)
;;       ;; => outcome
;;       ```
;;     %
(def (call-with-exception-boundary label thunk)
  (try
   (thunk)
   (catch (e)
     (log-exception-context label e)
     (reraise-exception e))))

;; run-checked
;;   : (-> (-> Outcome) String Outcome)
;;   | doc m%
;;       `run-checked` delegates diagnostics and re-raise behavior to the local
;;       boundary helper.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-checked thunk "job")
;;       ;; => outcome
;;       ```
;;     %
(def (run-checked thunk label)
  (call-with-exception-boundary label thunk))

;;; -*- Gerbil -*-    
;;; Boundary: guard, raise, and explicit error handling forms.    

(import :gerbil/gambit)    

(export guarded-value)    

(def (guarded-value thunk)
  (guard (exn
          (else
           ['error exn]))
    (let (value (thunk))
      (if value
        value
        (raise 'missing-value)))))    


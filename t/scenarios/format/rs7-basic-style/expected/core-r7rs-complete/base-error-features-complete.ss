;;; -*- Gerbil -*-
;;; Boundary: base error objects, file/read errors, and features procedure.

(define-library (fixture rs7 basic errors-complete)
  (export base-error-complete-sample)
  (import (scheme base))
  (begin
    (define (base-error-complete-sample value)
      (guard (exn
              ((file-error? exn)
               ['file (error-object-message exn)])
              ((read-error? exn)
               ['read (error-object-irritants exn)])
              ((error-object? exn)
               ['error (error-object-message exn)
                       (error-object-irritants exn)])
              (else
               ['unknown exn]))
        (if value
          (features)
          (error "missing value" value))))))

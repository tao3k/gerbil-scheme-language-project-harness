;;; -*- Gerbil -*-
;;; Boundary: with-exception-handler, raise, raise-continuable.

(import :gerbil/gambit)

(export exception-sample)

(def (exception-sample thunk)
  (with-exception-handler
    (lambda (exn)
      (raise-continuable ['handled exn]))
    (lambda ()
      (let (value (thunk))
        (if value
          value
          (raise 'missing))))))

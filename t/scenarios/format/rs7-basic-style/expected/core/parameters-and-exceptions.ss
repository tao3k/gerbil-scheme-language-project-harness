;;; -*- Gerbil -*-
;;; Boundary: dynamic parameters, exception boundaries, and cleanup style.

(import :gerbil/gambit)

(export with-policy-root
        current-policy-root)

(def current-policy-root
  (make-parameter "."))

(def (with-policy-root root thunk)
  (parameterize ((current-policy-root root))
    (with-catch
      (lambda (exn)
        (string-append "failed:" (current-policy-root)))
      (lambda ()
        (dynamic-wind
          void
          thunk
          void)))))

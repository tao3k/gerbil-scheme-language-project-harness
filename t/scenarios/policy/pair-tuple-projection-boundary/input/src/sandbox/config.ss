;;; -*- Gerbil -*-
;;; Agent-authored sandbox config with a temporary Pair tuple protocol.
(package: sample/sandbox)
(export sandbox-config sandbox-backend-ref)

;; profile-form
;;   : (-> Symbol ProfileForms Form Form)
;;   | type ProfileForms = (List Form)
;;   | type Form = (List Any)
;;   | doc m%
;;       `profile-form key forms` returns the first profile form for `key`.
;;     %
(def (profile-form key forms default-value)
  (cond
   ((null? forms) default-value)
   ((and (pair? (car forms))
         (eq? (caar forms) key))
    (car forms))
   (else
    (profile-form key (cdr forms) default-value))))

;; profile-tail
;;   : (-> Form (List Any))
;;   | type Form = (List Any)
;;   | doc m%
;;       `profile-tail form` removes the symbolic form tag.
;;     %
(def (profile-tail form)
  (if (and form (pair? form))
    (cdr form)
    '()))

;; backend-values
;;   : (-> ProfileForms Pair)
;;   | type ProfileForms = (List Form)
;;   | type Form = (List Any)
;;   | doc m%
;;       `backend-values forms` returns a temporary pair consumed by the config
;;       projection helpers.
;;     %
(def (backend-values forms)
  (let* ((backend-form
          (profile-form 'backend forms '(backend nono nono-sandbox)))
         (backend-payload (profile-tail backend-form))
         (backend-kind (if (null? backend-payload)
                         'nono
                         (car backend-payload)))
         (backend-ref (if (or (null? backend-payload)
                              (null? (cdr backend-payload)))
                        backend-kind
                        (cadr backend-payload))))
    (cons backend-kind backend-ref)))

;; sandbox-config
;;   : (-> Symbol ProfileForms Config)
;;   | type ProfileForms = (List Form)
;;   | type Config = (List Any)
;;   | doc m%
;;       `sandbox-config name forms` builds the public sandbox config.
;;     %
(def (sandbox-config name forms)
  (let (backend (backend-values forms))
    (list 'sandbox name (car backend) (cdr backend))))

;; sandbox-backend-ref
;;   : (-> ProfileForms Symbol)
;;   | type ProfileForms = (List Form)
;;   | doc m%
;;       `sandbox-backend-ref forms` projects the backend reference.
;;     %
(def (sandbox-backend-ref forms)
  (cdr (backend-values forms)))

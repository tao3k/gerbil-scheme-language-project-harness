(import :std/make
        :std/misc/path
        ./model
        ./native-toolchain)

;;; Keep the full public surface in one declaration so dependent facades receive
;;; the complete module interface during incremental compilation.
(export std-builder
        std-builder?
        make-std-builder
        std-builder-name
        std-builder-make-proc
        std-builder-stage-kind
        std-builder-description
        std-builder-srcdir
        std-builder-make-options
        std-builder-toolchain
        default-std-builder
        std-builder-effective-options
        std-builder-run-spec!
        std-builder-stage
        std-builder-stage-plan
        make-std-builder-profile
        make-std-builder-request
        build-request-stage-plan
        build-request-run!
        build-request->alist)

(defstruct std-builder
  (name make-proc stage-kind description srcdir make-options toolchain))

(def (default-std-builder (srcdir #f)
                          (make-options [])
                          (toolchain (native-toolchain-default)))
  (make-std-builder
   "std/make"
   make
   'std/make
   "Gerbil std/make stage runner"
   srcdir
   make-options
   toolchain))

(def (std-builder-effective-options builder extra-options)
  (append (std-builder-make-options builder) extra-options))

(def (std-builder-spec-list spec)
  (if (list? spec) spec [spec]))

(def (std-builder-run-spec! builder spec (extra-options []))
  (let ((stage (std-builder-spec-list spec))
        (options (std-builder-effective-options builder extra-options)))
    (with-native-toolchain
     (std-builder-toolchain builder)
     (lambda ()
       (if (std-builder-srcdir builder)
         (apply (std-builder-make-proc builder)
                stage
                srcdir: (std-builder-srcdir builder)
                options)
         (apply (std-builder-make-proc builder)
                stage
                options))))))

(def (std-builder-stage builder
                        label
                        spec
                        current-pred
                        (extra-options [])
                        (after (lambda (stage context result) #!void)))
  (make-build-stage
   label
   (std-builder-stage-kind builder)
   spec
   current-pred
   (lambda (stage context)
     (std-builder-run-spec! builder (build-stage-spec stage) extra-options))
   after
   (std-builder-description builder)))

;; : (forall (s) (-> s String))
;; default-std-builder-stage-label
;; : (-> Any String)
(def (default-std-builder-stage-label spec)
  (if (and (pair? spec) (string? (car spec)))
    (car spec)
    "std/make"))

;; : (forall (s c) (-> StdBuilder [s] (-> s c Boolean) [BuildStage]))
;; std-builder-stage-plan
;; : (-> StdBuilder List Procedure List)
(def (std-builder-stage-plan builder
                              stage-specs
                              current-pred
                              (label-of default-std-builder-stage-label)
                              (extra-options [])
                              (after (lambda (stage context result) #!void)))
  (map
   (lambda (spec)
     (std-builder-stage
      builder
      (label-of spec)
      spec
      (lambda (stage context)
        (current-pred (build-stage-spec stage) context))
      extra-options
      after))
   stage-specs))

;; : (forall (s) (-> StdBuilder (-> s String) [Any] Procedure BuildProfile))
;; make-std-builder-profile
;; : (-> StdBuilder Procedure List Procedure BuildProfile)
(def (make-std-builder-profile builder
                                (label-of default-std-builder-stage-label)
                                (extra-options [])
                                (after (lambda (stage context result) #!void)))
  (make-build-profile
   (std-builder-name builder)
   builder
   label-of
   extra-options
   after
   (std-builder-description builder)))

;; : (forall (s c) (-> String BuildProfile [s] (-> s c Boolean) c BuildRequest))
;; make-std-builder-request
;; : (-> String BuildProfile List Procedure Any BuildRequest)
(def (make-std-builder-request label profile stage-specs current-pred context)
  (make-build-request label profile stage-specs current-pred context))

;; : (-> BuildRequest [BuildStage])
;; build-request-stage-plan
;; : (-> BuildRequest List)
(def (build-request-stage-plan request)
  (let (profile (build-request-profile request))
    (std-builder-stage-plan
     (build-profile-builder profile)
     (build-request-stage-specs request)
     (build-request-current-pred request)
     (build-profile-label-of profile)
     (build-profile-extra-options profile)
     (build-profile-after profile))))

;; : (-> BuildRequest [BuildStageReceipt])
;; build-request-run!
;; : (-> BuildRequest List)
(def (build-request-run! request)
  (build-plan-run!
   (build-request-stage-plan request)
   (build-request-context request)))

;; : (-> BuildRequest Alist)
;; build-request->alist
;; : (-> BuildRequest Alist)
(def (build-request->alist request)
  (let (profile (build-request-profile request))
    `((label . ,(build-request-label request))
      (profile . ,(build-profile-name profile))
      (description . ,(build-profile-description profile))
      (stage-count . ,(length (build-request-stage-specs request))))))

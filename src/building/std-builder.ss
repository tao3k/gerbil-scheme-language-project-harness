(import (only-in :gerbil/gambit
                 ##gc
                 file-exists?
                 file-info
                 file-info-last-modification-time
                 getenv
                 read
                 string-length
                 substring
                 time->seconds)
        (only-in :std/make make make-clean)
        :std/misc/path
        (only-in :std/srfi/1 filter filter-map)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
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
        std-builder-clean-spec!
        std-builder-stage
        std-builder-stage-plan
        make-std-builder-profile
        make-std-builder-request
        build-request-stage-plan
        build-request-run!
        build-request-clean!
        build-requests-run!
        build-requests-clean!
        package-source-stage
        package-source-stage?
        make-package-source-stage
        package-source-stage-label
        package-source-stage-source
        package-source-stage-prefix
        package-source-stage-specs
        package-source-stage-batched?
        package-source-stage-current?
        source-topology-layers
        source-topology-affected
        package-source-stage-dependencies
        package-source-stage-topology-layers
        package-source-stage->request
        package-source-stages->requests
        package-source-stages-spec
        package-source-stages-run!
        package-source-stages-clean!
        build-request->alist)

(defstruct std-builder
  (name make-proc stage-kind description srcdir make-options toolchain))

;;; Boundary: projects declare source topology and phase ordering; std-builder
;;; remains the sole compiler, concurrency, native-toolchain, and clean owner.
(defstruct package-source-stage
  (label source prefix specs batched?))

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
    (let (result
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
                      options)))))
      result)))

;; : (-> StdBuilder List [BuildOption] Any)
(def (std-builder-clean-spec! builder spec (extra-options []))
  (let ((stage (std-builder-spec-list spec))
        (options (std-builder-effective-options builder extra-options)))
    (with-native-toolchain
     (std-builder-toolchain builder)
     (lambda ()
       (if (std-builder-srcdir builder)
         (apply make-clean stage srcdir: (std-builder-srcdir builder) options)
         (apply make-clean stage options))))))

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

;; : (-> BuildRequest Any)
(def (build-request-clean! request)
  (let (profile (build-request-profile request))
    (map (lambda (spec)
           (std-builder-clean-spec!
            (build-profile-builder profile)
            spec
            (build-profile-extra-options profile)))
         (build-request-stage-specs request))))

;; : (-> [BuildRequest] [BuildStageReceipt])
(def (build-requests-run! requests)
  (apply append (map build-request-run! requests)))

;; : (-> [BuildRequest] [Any])
(def (build-requests-clean! requests)
  (map build-request-clean! requests))

;; : (-> PackageSourceStage [[BuildSpec]])
(def (package-source-stage-request-specs stage)
  (let (specs (package-source-stage-specs stage))
    (cond
     ((eq? (package-source-stage-batched? stage) 'topology)
      (package-source-stage-topology-request-specs stage))
     ((package-source-stage-batched? stage)
      (list specs))
     (else
      (map list specs)))))

;; : (-> BuildSpec ModulePath)
(def (package-source-spec-module spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec)
         (pair? (cdr spec))
         (string? (cadr spec)))
    (cadr spec))
   (else
    (error "package source stage requires a module source spec" spec))))

(def (package-source-spec-ssi? spec)
  (and (pair? spec)
       (eq? (car spec) 'ssi:)))

;; : (-> ModulePath ModulePath)
(def (package-source-module-stem module)
  (let (length (string-length module))
    (if (and (>= length 3)
             (equal? (substring module (- length 3) length) ".ss"))
      (substring module 0 (- length 3))
      module)))

;; : (-> PackageSourceStage BuildSpec Path)
(def (package-source-stage-source-path stage spec)
  (path-expand
   (package-source-spec-module spec)
   (package-source-stage-source stage)))

;; : (-> PackageSourceStage BuildSpec Path)
(def (package-source-stage-output-path stage spec)
  (path-expand
   (string-append
    (package-source-stage-prefix stage)
    "/"
    (package-source-module-stem (package-source-spec-module spec))
    ".ssi")
   (path-expand "lib" (or (getenv "GERBIL_PATH") ".gerbil"))))

;; : (-> Path Integer)
(def (package-source-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; : (-> PackageSourceStage BuildSpec [ModulePath] Boolean)
(def (package-source-spec-artifact-current? stage spec dependencies)
  (let ((source (package-source-stage-source-path stage spec))
        (output (package-source-stage-output-path stage spec)))
    (and (file-exists? source)
         (file-exists? output)
         (<= (package-source-file-seconds source)
             (package-source-file-seconds output))
         (or (package-source-spec-ssi? spec)
             (andmap
              (lambda (dependency)
                (let (dependency-output
                      (package-source-stage-output-path stage dependency))
                  (and (file-exists? dependency-output)
                       (<= (package-source-file-seconds dependency-output)
                           (package-source-file-seconds output)))))
              dependencies)))))

;; : (-> PackageSourceStage BuildSpec Boolean)
(def (package-source-spec-current? stage spec)
  (package-source-spec-artifact-current?
   stage
   spec
   (if (eq? (package-source-stage-batched? stage) 'topology)
     (package-source-stage-dependencies
      stage (package-source-spec-module spec))
     [])))

;; : (-> PackageSourceStage [BuildSpec] Boolean)
(def (package-source-stage-current? stage specs)
  (and (pair? specs)
       (andmap (lambda (spec)
                 (package-source-spec-current? stage spec))
               specs)))

;; : (forall (n) (-> n [n] (-> n [n]) Boolean))
(def (source-topology-ready? node remaining dependencies-of)
  (not (ormap (lambda (dependency)
                (member dependency remaining))
              (dependencies-of node))))

;; : (forall (n) (-> [n] [n] [n]))
(def (source-topology-without nodes removed)
  (filter (lambda (node)
            (not (member node removed)))
          nodes))

;; : (forall (n) (-> [n] (-> n [n]) [[n]]))
(def (source-topology-layers nodes dependencies-of)
  (let loop ((remaining nodes) (layers []))
    (if (null? remaining)
      (reverse layers)
      (let (ready
            (filter (lambda (node)
                      (source-topology-ready?
                       node remaining dependencies-of))
                    remaining))
        (if (null? ready)
          (error "source topology contains a dependency cycle" remaining)
          (loop (source-topology-without remaining ready)
                (cons ready layers)))))))

;; : (forall (n) (-> [n] [n] (-> n [n]) [n]))
(def (source-topology-affected nodes stale dependencies-of)
  (let loop ((affected stale))
    (let (dependents
          (filter
           (lambda (node)
             (and (not (member node affected))
                  (ormap (lambda (dependency)
                           (member dependency affected))
                         (dependencies-of node))))
           nodes))
      (if (null? dependents)
        (filter (lambda (node) (member node affected)) nodes)
        (loop (append affected dependents))))))

;; : (-> String String)
(def (package-source-module-path module)
  (if (string-suffix? ".ss" module)
    module
    (string-append module ".ss")))

;; : (-> PackageSourceStage ModulePath Datum (Maybe ModulePath))
(def (package-source-import-reference stage owner reference)
  (cond
   ((symbol? reference)
    (let* ((name (symbol->string reference))
           (prefix (string-append ":" (package-source-stage-prefix stage) "/")))
      (and (string-prefix? prefix name)
           (package-source-module-path
            (substring name (string-length prefix) (string-length name))))))
   ((and (string? reference) (string-prefix? "." reference))
    (let* ((root (path-normalize (package-source-stage-source stage)))
           (directory (path-expand (path-directory owner) root))
           (absolute (path-normalize (path-expand reference directory))))
      (package-source-module-path
       (substring absolute
                  (+ (string-length root)
                     (if (string-suffix? "/" root) 0 1))
                  (string-length absolute)))))
   (else #f)))

;; : (-> PackageSourceStage ModulePath Datum [ModulePath])
(def (package-source-import-references stage owner datum)
  (cond
   ((pair? datum)
    (apply append
           (map (lambda (item)
                  (package-source-import-references stage owner item))
                datum)))
   (else
    (let (module (package-source-import-reference stage owner datum))
      (if module [module] [])))))

;; : (-> Datum Boolean)
(def (package-source-module-header-form? form)
  (and (pair? form)
       (memq (car form)
             '(import export package: namespace declare prelude:))))

;; : (-> Path [Datum])
(def (package-source-read-import-forms path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((forms []))
        (let (form (read port))
          (cond
           ((eof-object? form) (reverse forms))
           ((and (pair? form) (memq (car form) '(import export)))
            (loop (cons form forms)))
           ((package-source-module-header-form? form)
            (loop forms))
           (else (reverse forms))))))))

;; : (-> PackageSourceStage ModulePath [ModulePath])
(def (package-source-stage-dependencies stage module)
  (let* ((modules (map package-source-spec-module
                       (package-source-stage-specs stage)))
         (forms
          (package-source-read-import-forms
           (package-source-stage-source-path stage module))))
    (filter
     (lambda (dependency) (member dependency modules))
     (apply append
            (filter-map
             (lambda (form)
               (and (pair? form)
                    (memq (car form) '(import export))
                    (package-source-import-references stage module (cdr form))))
             forms)))))

;; : (-> PackageSourceStage [[ModulePath]])
(def (package-source-stage-topology-layers stage)
  (let (modules (map package-source-spec-module
                      (package-source-stage-specs stage)))
    (source-topology-layers
     modules
     (lambda (module)
       (package-source-stage-dependencies stage module)))))

;; : (-> PackageSourceStage [[ModulePath]])
(def (package-source-stage-topology-request-specs stage)
  (let* ((specs (package-source-stage-specs stage))
         (modules (map package-source-spec-module specs))
         (specs-by-module
          (map (lambda (spec)
                 (cons (package-source-spec-module spec) spec))
               specs))
         (dependencies
          (map (lambda (module)
                 (cons module
                       (package-source-stage-dependencies stage module)))
               modules))
         (dependencies-of
          (lambda (module) (cdr (assoc module dependencies))))
         (layers (source-topology-layers modules dependencies-of))
         (stale
         (filter
           (lambda (module)
             (not (package-source-spec-artifact-current?
                   stage
                   (cdr (assoc module specs-by-module))
                   (dependencies-of module))))
           modules))
         (affected
          (source-topology-affected modules stale dependencies-of)))
    (filter-map
     (lambda (layer)
       (let (selected
             (filter (lambda (module) (member module affected)) layer))
         (and (pair? selected)
              (map (lambda (module)
                     (cdr (assoc module specs-by-module)))
                   selected))))
     layers)))

;; : (-> PackageSourceStage [BuildOption] BuildRequest)
(def (package-source-stage->request stage options)
  (let* ((label (package-source-stage-label stage))
         (builder
          (default-std-builder
           (package-source-stage-source stage)
           (append
            options
            [prefix: (package-source-stage-prefix stage)])))
         (profile
          (make-std-builder-profile
           builder
           (lambda (spec)
             (string-append
              label
              " modules="
              (number->string (length spec)))))))
    (make-std-builder-request
     label
     profile
     (package-source-stage-request-specs stage)
     (lambda (specs context)
       (package-source-stage-current? context specs))
     stage)))

;; : (-> [PackageSourceStage] [BuildOption] [BuildRequest])
(def (package-source-stages->requests stages options)
  (map (lambda (stage)
         (package-source-stage->request stage options))
       stages))

;; : (-> [PackageSourceStage] [[BuildSpec]])
(def (package-source-stages-spec stages)
  (map (lambda (stage)
         (let (specs (package-source-stage-specs stage))
           (if (package-source-stage-batched? stage)
             (list specs)
             (map list specs))))
       stages))

;; : (-> [PackageSourceStage] [BuildOption] [BuildStageReceipt])
(def (package-source-stages-run! stages options)
  (build-requests-run!
   (package-source-stages->requests stages options)))

;; : (-> [PackageSourceStage] [Any])
(def (package-source-stages-clean! stages)
  (build-requests-clean!
   (package-source-stages->requests stages [])))

;; : (-> BuildRequest Alist)
;; build-request->alist
;; : (-> BuildRequest Alist)
(def (build-request->alist request)
  (let (profile (build-request-profile request))
    `((label . ,(build-request-label request))
      (profile . ,(build-profile-name profile))
      (description . ,(build-profile-description profile))
      (stage-count . ,(length (build-request-stage-specs request))))))

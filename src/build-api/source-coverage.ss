;;; -*- Gerbil -*-
;;; Build-time ASP source coverage declarations.

(import :gerbil/gambit
        (only-in :clan/building all-gerbil-modules)
        (only-in :std/misc/path path-expand)
        (only-in :std/sort sort))

(export gslph-source-coverage
        gslph-load-source-coverage
        gslph-source-coverage-roots
        gslph-source-coverage-runtime-roots
        gslph-source-coverage-exclude-directories
        gslph-source-coverage-files)

;; : (List Path)
(def current-source-coverage-roots '("src"))
;; : (Maybe (List Path))
(def current-source-coverage-runtime-roots #f)
;; : (List Path)
(def current-source-coverage-exclude-directories '())

;; `build.ss` files call this declaration so ASP can parse the project source
;; coverage universe. Build support also consumes the same declaration so policy
;; gates and std/make coverage stay tied to the package's build entrypoint.
;; : (-> roots: (List Path) runtime-roots: (Maybe (List Path)) exclude-directories: (List Path) explanation: MaybeString Unit)
(def (gslph-source-coverage roots: (roots '())
                            runtime-roots: (runtime-roots #f)
                            exclude-directories: (exclude-directories '())
                            explanation: (explanation #f))
  (set! current-source-coverage-roots roots)
  (set! current-source-coverage-runtime-roots runtime-roots)
  (set! current-source-coverage-exclude-directories exclude-directories)
  #!void)

;; : (-> Root Unit)
(def (gslph-load-source-coverage root)
  (let (build-file (path-expand "build.ss" root))
    (when (file-exists? build-file)
      (with-directory root
        (lambda ()
          (load build-file))))))

;; : (-> (List Path))
(def (gslph-source-coverage-roots)
  current-source-coverage-roots)

;; : (-> (List Path))
(def (gslph-source-coverage-runtime-roots)
  (or current-source-coverage-runtime-roots
      current-source-coverage-roots))

;; : (-> (List Path))
(def (gslph-source-coverage-exclude-directories)
  current-source-coverage-exclude-directories)

;; : (-> Root (List Path))
(def (gslph-source-coverage-files root)
  (sort (apply append
               (map (lambda (coverage-root)
                      (source-coverage-root-files root coverage-root))
                    (gslph-source-coverage-roots)))
        string<?))

;; : (-> Root Path (List Path))
(def (source-coverage-root-files root coverage-root)
  (let (directory (path-expand coverage-root root))
    (with-directory directory
      (lambda ()
        (map (lambda (path)
               (string-append coverage-root "/" path))
             (all-gerbil-modules
              exclude-dirs: (gslph-source-coverage-exclude-directories)))))))

;; : (forall (a) (-> Path (-> a) a))
(def (with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))

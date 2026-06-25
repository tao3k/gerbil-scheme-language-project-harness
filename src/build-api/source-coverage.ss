;;; -*- Gerbil -*-
;;; Build-time ASP source coverage declarations.

(import :gerbil/gambit)

(export gslph-source-coverage
        gslph-source-coverage-roots
        gslph-source-coverage-runtime-roots
        gslph-source-coverage-exclude-directories)

;; : (List Path)
(def current-source-coverage-roots '("src"))
;; : (Maybe (List Path))
(def current-source-coverage-runtime-roots #f)
;; : (List Path)
(def current-source-coverage-exclude-directories '())

;; `build.ss` files call this declaration so ASP can parse the project source
;; coverage universe. Build support also consumes the same declaration so policy
;; gates and std/make coverage stay tied to the package's build entrypoint.
;; : (-> roots: (List Path)
;;       runtime-roots: (Maybe (List Path))
;;       exclude-directories: (List Path)
;;       explanation: MaybeString
;;       Unit)
(def (gslph-source-coverage roots: (roots '())
                            runtime-roots: (runtime-roots #f)
                            exclude-directories: (exclude-directories '())
                            explanation: (explanation #f))
  (set! current-source-coverage-roots roots)
  (set! current-source-coverage-runtime-roots runtime-roots)
  (set! current-source-coverage-exclude-directories exclude-directories)
  #!void)

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

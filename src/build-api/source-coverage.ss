;;; -*- Gerbil -*-
;;; Build-time ASP source coverage declarations.

(import :gerbil/gambit)

(export gslph-source-coverage)

;; `build.ss` files call this declaration so ASP can parse the project source
;; coverage universe without executing the build. Runtime behavior is inert.
(def (gslph-source-coverage roots: (roots '())
                            runtime-roots: (runtime-roots #f)
                            exclude-directories: (exclude-directories '())
                            explanation: (explanation #f))
  #!void)

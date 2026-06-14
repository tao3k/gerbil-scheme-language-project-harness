;;; -*- Gerbil -*-
;;; Gerbil package-manager facts derived from gerbil.pkg.

(import :parser/facade)

(export +gerbil-package-manager-id+
        project-package-managed-by-gerbil?
        project-package-depends-on?
        project-package-activates?)
;; String
(def +gerbil-package-manager-id+ "gxpkg")
;; Boolean <- Package
(def (project-package-managed-by-gerbil? package)
  (and package
       (equal? (project-package-manager package) +gerbil-package-manager-id+)))
;;; Boundary:
;;; - project-package-activates? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- Package TokenMatches
(def (project-package-activates? package token-matches?)
  (and (project-package-managed-by-gerbil? package)
       (not
        (not
         (or (token-matches? (project-package-name package))
             (ormap token-matches? (project-package-dependencies package)))))))
;;; Boundary:
;;; - project-package-depends-on? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- Package TokenMatches
(def (project-package-depends-on? package token-matches?)
  (and (project-package-managed-by-gerbil? package)
       (not
        (not
         (ormap token-matches? (project-package-dependencies package))))))

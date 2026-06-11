;;; -*- Gerbil -*-
;;; Gerbil package-manager facts derived from gerbil.pkg.

(import :parser/facade)

(export +gerbil-package-manager-id+
        project-package-managed-by-gerbil?
        project-package-depends-on?
        project-package-activates?)

(def +gerbil-package-manager-id+ "gxpkg")

(def (project-package-managed-by-gerbil? package)
  (and package
       (equal? (project-package-manager package) +gerbil-package-manager-id+)))

(def (project-package-activates? package token-matches?)
  (and (project-package-managed-by-gerbil? package)
       (not
        (not
         (or (token-matches? (project-package-name package))
             (ormap token-matches? (project-package-dependencies package)))))))

(def (project-package-depends-on? package token-matches?)
  (and (project-package-managed-by-gerbil? package)
       (not
        (not
         (ormap token-matches? (project-package-dependencies package))))))

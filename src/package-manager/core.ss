;;; -*- Gerbil -*-
;;; Gerbil package-manager facts derived from gerbil.pkg.

(import :parser/facade)

(export +gerbil-package-manager-id+
        +gerbil-local-package-root-hint+
        project-package-managed-by-gerbil?
        project-package-depends-on?
        project-package-activates?
        gerbil-local-source-candidate
        git-repository-candidate
        package-source-index-hint)
;; String
(def +gerbil-package-manager-id+ "gxpkg")
;; String
(def +gerbil-local-package-root-hint+ "~/.gerbil")
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
;; Json <- PackageName
(def (gerbil-local-source-candidate package-name)
  (hash (kind "gerbil-package-source")
        (manager +gerbil-package-manager-id+)
        (rootHint +gerbil-local-package-root-hint+)
        (package package-name)
        (status "probe-first")
        (missingAction "install-package-before-repository-fallback")
        (installHint
         (string-append +gerbil-package-manager-id+ " install " package-name))
        (owner "asp-client")))
;; Json <- Repository
(def (git-repository-candidate repository)
  (hash (kind "git-repository")
        (vcs "git")
        (repository repository)
        (url (string-append "https://" repository))
        (status "fallback")
        (owner "asp-client")))
;; Json
(def (package-source-index-hint)
  (hash (owner "asp-client")
        (backend "rust-sql")
        (mode "local-source-before-git")
        (packageManager +gerbil-package-manager-id+)
        (missingLocalAction "install-package-before-repository-fallback")
        (fallbackPolicy "repository-source-after-install-check")))

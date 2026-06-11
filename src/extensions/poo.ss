;;; -*- Gerbil -*-
;;; Gerbil-poo package extension facts activated by declared gxpkg dependencies.

(import :extensions/model
        :package-manager/facade
        :parser/facade)

(export poo-extension-active?
        poo-extension-fact
        poo-extension-capability-names
        poo-extension-search-lines
        poo-extension-json)

(def +poo-extension-name+ "poo")
(def +poo-extension-activation+ "gerbil.pkg")
(def +poo-dependency-mode+ "required")
(def +poo-package-tokens+
  '("poo" "clan/poo" "gerbil-poo" "git.cons.io/mighty-gerbils/gerbil-poo"))

(def (poo-extension-active? index)
  (project-package-depends-on? (project-index-package index)
                               poo-package-token?))

(def (poo-package-token? token)
  (and token
       (or (member token +poo-package-tokens+)
           (string-suffix? "/gerbil-poo" token))))

(def (poo-extension-capability-names)
  '("object-system" "metaobject-protocol" "protocols"))

(def (poo-extension-fact index)
  (and (poo-extension-active? index)
       (let (package (project-index-package index))
         (make-extension-fact +poo-extension-name+
                              +poo-extension-activation+
                              +poo-dependency-mode+
                              (project-package-manager package)
                              (project-package-name package)
                              (project-package-dependencies package)
                              (poo-extension-capability-names)))))

(def (poo-extension-search-lines index)
  (let (fact (poo-extension-fact index))
    (if fact
      [(extension-fact-search-line fact)]
      '())))

(def (poo-extension-json index)
  (let (fact (poo-extension-fact index))
    (and fact (extension-fact-json fact))))

(def (string-suffix? suffix text)
  (let ((suffix-length (string-length suffix))
        (text-length (string-length text)))
    (and (fx<= suffix-length text-length)
         (equal? suffix
                 (substring text (fx- text-length suffix-length) text-length)))))

;;; -*- Gerbil -*-
;;; Optional Gerbil-poo package extension facts.

(import :package-manager/facade
        :parser/facade
        :std/srfi/13)

(export poo-extension-active?
        poo-extension-capability-names
        poo-extension-search-lines
        poo-extension-json)

(def (poo-extension-active? index)
  (project-package-activates? (project-index-package index)
                              poo-package-token?))

(def (poo-package-token? token)
  (and token
       (or (equal? token "clan/poo")
           (equal? token "poo")
           (string-contains token "gerbil-poo"))))

(def (poo-extension-capability-names)
  '("object-system" "metaobject-protocol" "protocols"))

(def (poo-extension-search-lines index)
  (if (poo-extension-active? index)
    [(poo-extension-summary-line index)]
    '()))

(def (poo-extension-summary-line index)
  (let (package (project-index-package index))
    (string-append
     "|extension name=poo activation=gerbil.pkg packageManager="
     (project-package-manager package)
     " package="
     (project-package-name package)
     " dependencies="
     (join-strings (project-package-dependencies package) ",")
     " capabilities="
     (join-strings (poo-extension-capability-names) ","))))

(def (poo-extension-json index)
  (and (poo-extension-active? index)
       (let (package (project-index-package index))
         (hash (name "poo")
               (activation "gerbil.pkg")
               (packageManager (project-package-manager package))
               (package (project-package-name package))
               (dependencies (project-package-dependencies package))
               (capabilities (poo-extension-capability-names))))))

(def (join-strings items separator)
  (let lp ((rest items) (out ""))
    (match rest
      ([] out)
      ([item]
       (if (equal? out "")
         item
         (string-append out separator item)))
      ([item . more]
       (lp more
           (if (equal? out "")
             item
             (string-append out separator item)))))))

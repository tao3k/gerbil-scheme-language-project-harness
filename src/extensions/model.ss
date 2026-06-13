;;; -*- Gerbil -*-
;;; Provider-owned extension fact model.

(import :std/sugar
        :support/list)

(export extension-fact
        make-extension-fact
        extension-fact?
        extension-fact-name
        extension-fact-activation
        extension-fact-dependency-mode
        extension-fact-package-manager
        extension-fact-package
        extension-fact-dependencies
        extension-fact-capabilities
        extension-fact-json
        extension-fact-search-line)

(defstruct extension-fact (name activation dependency-mode package-manager package dependencies capabilities))

(def (extension-fact-json fact)
  (hash (name (extension-fact-name fact))
        (activation (extension-fact-activation fact))
        (dependencyMode (extension-fact-dependency-mode fact))
        (packageManager (extension-fact-package-manager fact))
        (package (extension-fact-package fact))
        (dependencies (extension-fact-dependencies fact))
        (capabilities (extension-fact-capabilities fact))))

(def (extension-fact-search-line fact)
  (string-append
   "|extension name="
   (extension-fact-name fact)
   " activation="
   (extension-fact-activation fact)
   " packageManager="
   (extension-fact-package-manager fact)
   " dependencyMode="
   (extension-fact-dependency-mode fact)
   " package="
   (extension-fact-package fact)
   " dependencies="
   (join (extension-fact-dependencies fact) ",")
   " capabilities="
   (join (extension-fact-capabilities fact) ",")))

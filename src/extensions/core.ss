;;; -*- Gerbil -*-
;;; Extension aggregation for provider-owned Gerbil package capabilities.

(import :extensions/model
        :extensions/poo)

(export project-extension-facts
        project-extension-search-lines
        project-extension-json)

(def (project-extension-facts index)
  (filter-map
   (lambda (extension) extension)
   [(poo-extension-fact index)]))

(def (project-extension-search-lines index)
  (map extension-fact-search-line (project-extension-facts index)))

(def (project-extension-json index)
  (map extension-fact-json (project-extension-facts index)))

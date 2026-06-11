;;; -*- Gerbil -*-
;;; Extension aggregation for optional Gerbil package capabilities.

(import :extensions/poo)

(export project-extension-search-lines
        project-extension-json)

(def (project-extension-search-lines index)
  (poo-extension-search-lines index))

(def (project-extension-json index)
  (filter-map
   (lambda (extension) extension)
   [(poo-extension-json index)]))

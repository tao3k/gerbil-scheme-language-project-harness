;;; -*- Gerbil -*-
;;; Extension aggregation for provider-owned Gerbil package capabilities.

(import :extensions/model
        :extensions/poo)

(export project-extension-facts
        project-extension-search-lines
        project-extension-json)
;;; Boundary:
;;; - project-extension-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Fact) <- ProjectIndex
(def (project-extension-facts index)
  (filter-map
   (lambda (extension) extension)
   [(poo-extension-fact index)]))
;;; Boundary:
;;; - project-extension-search-lines composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- ProjectIndex
(def (project-extension-search-lines index)
  (map extension-fact-search-line (project-extension-facts index)))
;;; Boundary:
;;; - project-extension-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Json <- ProjectIndex
(def (project-extension-json index)
  (map extension-fact-json (project-extension-facts index)))

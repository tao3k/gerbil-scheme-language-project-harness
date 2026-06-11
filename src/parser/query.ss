;;; -*- Gerbil -*-
;;; Query helpers over parser-owned project facts.

(import :parser/parser
        :support/list
        :std/sort
        :std/srfi/13)

(export matching-definitions
        ranked-files
        ranked-query-files)

(def (matching-definitions definitions terms)
  (if (null? terms)
    definitions
    (filter
     (lambda (defn)
       (ormap (lambda (term)
                (string-contains (string-downcase (definition-name defn))
                                 (string-downcase term)))
              terms))
     definitions)))

(def (ranked-files index)
  (sort (project-index-files index)
        (lambda (a b)
          (> (length (source-file-definitions a))
             (length (source-file-definitions b))))))

(def (ranked-query-files index query)
  (filter
   (lambda (file)
     (let (haystack
           (string-append (source-file-path file) " "
                          (or (source-file-package file) "") " "
                          (join (source-file-imports file) " ") " "
                          (join (map definition-name (source-file-definitions file)) " ")))
       (string-contains (string-downcase haystack) (string-downcase query))))
   (ranked-files index)))

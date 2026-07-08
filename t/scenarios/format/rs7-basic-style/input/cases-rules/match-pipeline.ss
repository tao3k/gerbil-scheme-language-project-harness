;;; -*- Gerbil -*-
;;; Boundary: lambda/match pipeline with local helpers.    

(import :gerbil/gambit
        :std/match
        :std/srfi/1)    

(export collect-public-rules)    

(def (collect-public-rules entries)
  (filter-map
   (lambda (entry)
     (match entry
       (['rule name public? message]
        (and public?
             [name message]))
       (else #f)))
   entries))    


;;; -*- Gerbil -*-    
;;; Boundary: record-style declarations, predicates, accessors, and updates.    

(import :gerbil/gambit)    

(export make-node
        node?
        node-name
        node-value
        update-node-value)    

(defstruct node (name value)
  transparent: #t)    

(def (update-node-value item value)
  (if (node? item)
    (make-node (node-name item) value)
    item))    


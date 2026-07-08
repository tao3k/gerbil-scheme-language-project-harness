;;; -*- Gerbil -*-   
;;; Boundary: module boundary, nested exports, and local imports.   

(import :gerbil/gambit)   

(export make-renderer)   

(module renderer
  (export render)
  (def (render name value)
    (string-append name "=" value)))   

(def (make-renderer prefix)
  (lambda (name value)
    (renderer#render
     (string-append prefix "/" name)
     value)))   


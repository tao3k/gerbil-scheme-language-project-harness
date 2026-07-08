;;; -*- Gerbil -*-	
;;; Boundary: port-based IO shape and nested output expressions.  

(import :gerbil/gambit)  

(export write-lines-to-string)  

(def (write-lines-to-string lines)
  (call-with-output-string
    (lambda (port)
      (for-each
       (lambda (line)
         (display line port)
         (newline port))
       lines))))  


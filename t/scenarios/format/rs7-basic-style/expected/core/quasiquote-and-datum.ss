;;; -*- Gerbil -*-
;;; Boundary: quote, quasiquote, vectors, lists, and datum comments.

(import :gerbil/gambit)

(export build-template
        +reader-data+)

(def +reader-data+
  '#(alpha beta gamma))

(def (build-template name fields)
  `(packet
    (name . ,name)
    (fields . ,fields)
    (literal . #(1 2 3))
    (items . ,@(map (lambda (field) `((field . ,field))) fields))))

#; (def ignored-by-reader
     '(this datum comment must remain aligned as input text))

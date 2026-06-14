;;; -*- Gerbil -*-
;;; Shared helpers for protocol JSON projections.

(export fact-location-json
        native-syntax-fact-id)

;; Json <- String Integer Integer
(def (fact-location-json path start end)
  (hash (path path)
        (lineRange (string-append (number->string start)
                                  ":"
                                  (number->string end)))))

;; String <- String String String Integer
(def (native-syntax-fact-id kind path name start)
  (string-append kind ":"
                 path ":"
                 (number->string start) ":"
                 name))

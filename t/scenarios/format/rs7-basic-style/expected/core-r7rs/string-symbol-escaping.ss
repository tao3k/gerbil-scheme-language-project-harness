;;; -*- Gerbil -*-
;;; Boundary: string escapes, vertical-bar symbols, escaped identifiers.

(import :gerbil/gambit)

(export escaped-datum)

(def (escaped-datum)
  (list '|symbol with spaces|
        '|contains\|bar|
        'line\nsymbol
        "line one\nline two"
        "hex A: \x41;"
        "quote: \" and slash: \\"
        '|mixed\x20;space|))

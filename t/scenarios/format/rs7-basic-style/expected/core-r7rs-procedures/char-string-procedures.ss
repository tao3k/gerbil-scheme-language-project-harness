;;; -*- Gerbil -*-
;;; Boundary: character and string constructors, conversion, comparison.

(import :gerbil/gambit)

(export char-string-sample)

(def (char-string-sample text)
  (let ((copy (string-copy text)))
    (string-set! copy 0 (char-upcase (string-ref copy 0)))
    (list (char=? #\a #\a)
          (char<? #\a #\b)
          (char->integer #\A)
          (integer->char 65)
          (make-string 3 #\x)
          (string #\a #\b #\c)
          (string-length copy)
          (substring copy 0 1)
          (string-append copy "!")
          (string->list copy)
          (list->string '(#\o #\k))
          copy)))

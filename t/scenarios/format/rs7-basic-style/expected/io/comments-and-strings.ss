;;; -*- Gerbil -*-
;;; Boundary: strings and comments may contain visible whitespace that must stay.

(import :gerbil/gambit)

(export render-warning-line)

;; The formatter trims only trailing source whitespace, not string contents.
(def +literal-with-spaces+ "keep two spaces:  ")

(def (render-warning-line rule path line)
  (string-append
   rule
   " "
   path
   ":"
   (number->string line)
   +literal-with-spaces+))

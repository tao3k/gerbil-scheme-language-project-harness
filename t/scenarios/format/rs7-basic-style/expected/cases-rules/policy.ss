;;; -*- Gerbil -*-
;;; Boundary: policy-style file with exports, constants, and match clauses.

(import :gerbil/gambit
        :std/match)

(export policy-warning
        policy-warning?
        policy-warning-rule
        warning->line)

(defstruct policy-warning (rule path line message)
  transparent: #t)

(def (warning->line warning)
  (match warning
    ((policy-warning rule path line message)
     (string-append rule ":" path ":" (number->string line) " " message))
    (else
     "unknown warning")))

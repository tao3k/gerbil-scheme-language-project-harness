;;; -*- Gerbil -*-
;;; Boundary:
;;; - Binding parsing is grammar-owned, with failure and token construction at
;;;   the parser boundary instead of a hand-written string cursor state machine.
(package: sample/parser)
(import :std/parser)
(export parse-binding)

;; binding-token
;;   : (-> String BindingToken)
;;   | doc m%
;;       `binding-token` is the lexer boundary consumed by the parser grammar.
;;     %
(def (binding-token source)
  (make-token 'text source))

(defparser parse-binding-entry
  lexer: binding-token
  (Entry (@cat (Key $1) (@eq #\=) (Value $2) $$)
         => (cons $1 $2))
  (Key (@rep+ (NameChar $1))
       => (list->string $1))
  (Value (@rep* (NameChar $1))
         => (list->string $1))
  (NameChar
   (@eq #\=)
   !
   (@eq #\space)
   !
   (Char $1)
   => $1))

;; parse-binding
;;   : (-> String Binding)
;;   | requires source has exactly one separator
;;   | warning parser failures must stay source-aware
;;   | doc m%
;;       `parse-binding` delegates grammar shape and rewind/fail behavior to
;;       `parse-binding-entry`.
;;     %
(def (parse-binding source)
  (try
   (parse-binding-entry source)
   (catch (e)
     (raise-parse-error 'parse-binding source))))

;;; -*- Gerbil -*-
;;; Source-range transport helpers.

(import :gerbil/gambit
        :parser/facade
        :std/misc/ports
        :std/srfi/13)

(export read-definition-code
        read-selector
        split-selector
        read-line-range)

(def (read-definition-code root defn)
  (read-line-range (path-expand (definition-path defn) root)
                   (definition-start defn)
                   (definition-end defn)))

(def (read-selector root selector)
  (let* ((parts (split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts)))
    (read-line-range (path-expand path root) start end)))

(def (split-selector selector)
  (let* ((ix (string-index-right selector #\:))
         (path (substring selector 0 ix))
         (range (substring selector (fx1+ ix) (string-length selector)))
         (dash (string-index range #\-)))
    (if dash
      [path
       (string->number (substring range 0 dash))
       (string->number (substring range (fx1+ dash) (string-length range)))]
      [path (string->number range) (string->number range)])))

(def (read-line-range path start end)
  (let (lines (read-file-lines path))
    (let lp ((rest lines) (line 1) (out ""))
      (cond
       ((null? rest) out)
       ((> line end) out)
       ((>= line start)
        (lp (cdr rest) (fx1+ line) (string-append out (car rest) "\n")))
       (else
        (lp (cdr rest) (fx1+ line) out))))))

;;; -*- Gerbil -*-
;;; Signature loading for native type facts.

(import :types/model)

(export load-type-signatures
        parse-type-signature
        signature-type-for)
;;; Boundary:
;;; Signature files are trusted native S-expressions, so loading owns the only
;;; resource scope and rejects non-list payloads before signature projection.
;; NativeSignatures <- SignaturePath
(def (load-type-signatures path)
  (let (sexpr (call-with-input-file path read))
    (if (list? sexpr)
      (filter-map-signatures sexpr)
      '())))
;; TypeSpec <- Entry
(def (parse-type-signature entry)
  (and (pair? entry)
       (let ((name (signature-name (car entry)))
             (type-sexpr (signature-type-sexpr entry)))
         (and name (cons name (parse-type-sexpr type-sexpr))))))
;; TypeSpec <- String NativeSignatures
(def (signature-type-for name signatures)
  (let (found (assoc name signatures))
    (and found (cdr found))))
;; SignatureName <- String
(def (signature-name name)
  (cond
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else #f)))
;; TypeSpec <- Entry
(def (signature-type-sexpr entry)
  (let (tail (cdr entry))
    (if (and (pair? tail) (null? (cdr tail)))
      (car tail)
      tail)))
;;; Boundary:
;;; - filter-map-signatures composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; FilterMapSignatures <- (List XX)
(def (filter-map-signatures entries)
  (reverse
   (foldl (lambda (entry out)
            (let (signature (parse-type-signature entry))
              (if signature
                (cons signature out)
                out)))
          '()
          entries)))

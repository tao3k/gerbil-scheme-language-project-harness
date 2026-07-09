(import :std/sugar)

(export render-report render-row render-value)

(def (render-value value)
  (cond
   ((string? value) (string-append "\"" value "\""))
   ((number? value) (number->string value))
   ((eq? value #t) "true")
   ((eq? value #f) "false")
   (else "\"unknown\"")))

(def (render-row row)
  (string-append
   "{"
   "\"path\":" (render-value (hash-ref row 'path ""))
   ","
   "\"status\":" (render-value (hash-ref row 'status "unknown"))
   ","
   "\"findings\":" (render-value (hash-ref row 'findings 0))
   "}"))

(def (join-json rows)
  (let loop ((rest rows) (out ""))
    (cond
     ((null? rest) out)
     ((string=? out "")
      (loop (cdr rest) (render-row (car rest))))
     (else
      (loop (cdr rest)
            (string-append out "," (render-row (car rest))))))))

(def (render-report rows)
  (string-append "{\"rows\":[" (join-json rows) "]}"))

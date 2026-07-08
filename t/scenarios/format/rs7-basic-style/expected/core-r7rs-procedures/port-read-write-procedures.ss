;;; -*- Gerbil -*-
;;; Boundary: read/write/display, string ports, file port wrappers.

(import :gerbil/gambit)

(export port-sample)

(def (port-sample datum)
  (let ((rendered
         (call-with-output-string
           (lambda (port)
             (write datum port)
             (display " " port)
             (write-char #\x port)
             (newline port)))))
    (call-with-input-string rendered
      (lambda (port)
        (list (peek-char port)
              (read port)
              (read-char port)
              (eof-object? (read port)))))))

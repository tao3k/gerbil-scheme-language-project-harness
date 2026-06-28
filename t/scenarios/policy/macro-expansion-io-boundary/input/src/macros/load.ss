;;; -*- Gerbil -*-
(package: sample/macros)

(export load-fragment)

(defsyntax (load-fragment stx)
  (syntax-case stx ()
    ((_ path)
     (let* ((path-value (syntax->datum (syntax path)))
            (forms (call-with-input-file path-value
                     (lambda (port)
                       (let loop ((out '()))
                         (let (form (read port))
                           (if (eof-object? form)
                             (reverse out)
                             (loop (cons form out)))))))))
       (datum->syntax (syntax stx) (cons 'begin forms))))))

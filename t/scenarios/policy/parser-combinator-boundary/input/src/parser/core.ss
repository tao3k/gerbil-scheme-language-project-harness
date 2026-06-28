;;; -*- Gerbil -*-
;;; Parser facade with hand-written cursor state.
(package: sample/parser)
(export parse-binding)

;; : (-> String Parser Binding)
(def (parse-binding source)
  (let ((limit (string-length source)))
    (let loop ((i 0) (key-start 0) (saw-sep? #f))
      (cond
       ((>= i limit)
        (if saw-sep?
          (let ((key (substring source key-start 0))
                (value (substring source (+ key-start 1) limit)))
            (cons key value))
          (error "missing separator")))
       ((char=? (string-ref source i) #\=)
        (if saw-sep?
          (error "duplicate separator")
          (loop (+ i 1) i #t)))
       ((char-whitespace? (string-ref source i))
        (error "unexpected whitespace"))
       (else
        (loop (+ i 1) key-start saw-sep?))))))

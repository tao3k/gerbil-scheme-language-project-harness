;;; -*- Gerbil -*-
;;; Input: hides hot primitive calls behind a dynamic table and apply.
(package: scenario/gerbil-inline-rule-call-shape/input)
(export count-small)

(def primitive-table
  (list (cons 'small? (lambda (value limit) (< value limit)))
        (cons 'bump (lambda (count) (+ count 1)))))

(def (primitive name)
  (cdr (assq name primitive-table)))

(def (count-small values limit)
  (let ((small? (primitive 'small?))
        (bump (primitive 'bump)))
    (let loop ((rest values)
               (count 0))
      (if (null? rest)
        count
        (loop (cdr rest)
              (if (apply small? (list (car rest) limit))
                (apply bump (list count))
                count))))))

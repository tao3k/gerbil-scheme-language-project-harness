;;; -*- Gerbil -*-
;;; Command-line argument helpers.

(import :gerbil/gambit
        :support/list
        :std/srfi/13)

(export flag?
        option
        options
        positional-args
        project-root
        drop-project-root
        file-directory?)

(def +boolean-flags+ '("--json" "--code" "--names-only" "--changed" "--full"))
(def +value-options+ '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"))

(def (flag? flag args)
  (member flag args))

(def (option flag args)
  (match args
    ([] #f)
    ([hd value . rest]
     (if (equal? hd flag) value (option flag (cons value rest))))
    ([_] #f)))

(def (options flag args)
  (match args
    ([] '())
    ([hd value . rest]
     (if (equal? hd flag)
       (cons value (options flag rest))
       (options flag (cons value rest))))
    ([_] '())))

(def (positional-args args)
  (let lp ((rest args) (out '()))
    (match rest
      ([] (reverse out))
      ([hd value . more]
       (cond
        ((member hd +boolean-flags+)
         (lp (cons value more) out))
        ((member hd +value-options+)
         (lp more out))
        ((string-prefix? "--" hd)
         (lp (cons value more) out))
        (else
         (lp (cons value more) (cons hd out)))))
      ([hd]
       (if (string-prefix? "--" hd) (reverse out) (reverse (cons hd out)))))))

(def (project-root args)
  (let (pos (positional-args args))
    (if (and (pair? pos) (file-directory? (last pos)))
      (last pos)
      ".")))

(def (drop-project-root args)
  (let* ((pos (positional-args args))
         (root? (and (pair? pos) (file-directory? (last pos))))
         (root-index (and root? (length pos))))
    (if root?
      (drop-positional-index args root-index)
      args)))

(def (drop-positional-index args target-index)
  (let lp ((rest args)
           (out '())
           (index 0))
    (match rest
      ([] (reverse out))
      ([hd value . more]
       (cond
        ((member hd +boolean-flags+)
         (lp (cons value more) (cons hd out) index))
        ((member hd +value-options+)
         (lp more (cons value (cons hd out)) index))
        ((string-prefix? "--" hd)
         (lp (cons value more) (cons hd out) index))
        (else
         (let (next-index (fx1+ index))
           (if (fx= next-index target-index)
             (lp (cons value more) out next-index)
             (lp (cons value more) (cons hd out) next-index))))))
      ([hd]
       (cond
        ((string-prefix? "--" hd)
         (reverse (cons hd out)))
        (else
         (let (next-index (fx1+ index))
           (if (fx= next-index target-index)
             (reverse out)
             (reverse (cons hd out))))))))))

(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

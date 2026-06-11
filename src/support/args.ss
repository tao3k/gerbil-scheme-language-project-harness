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
        ((member hd '("--json" "--code" "--names-only" "--changed" "--full"))
         (lp (cons value more) out))
        ((member hd '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"))
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
         (root (and root? (last pos))))
    (if root?
      (filter (lambda (arg) (not (equal? arg root))) args)
      args)))

(def (file-directory? path)
  (eq? (file-type path) 'directory))

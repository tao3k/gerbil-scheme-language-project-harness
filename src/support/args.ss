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

(def +boolean-flags+ '("--json" "--code" "--names-only" "--changed" "--full" "--more"))
(def +value-options+
  '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"
    "--iterations" "--max-total-ms" "--whitelist"
    "--topic" "--intent" "--role" "--level" "--rule" "--finding" "--limit"))

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
  (let (state
        (foldl (lambda (arg state)
                 (let ((out (car state))
                       (skip-next? (cdr state)))
                   (cond
                    (skip-next? (cons out #f))
                    ((member arg +value-options+) (cons out #t))
                    ((or (member arg +boolean-flags+)
                         (string-prefix? "--" arg))
                     (cons out #f))
                    (else (cons (cons arg out) #f)))))
               (cons '() #f)
               args))
    (reverse (car state))))

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
  (let (state
        (foldl (lambda (arg state)
                 (let ((out (car state))
                       (index (cadr state))
                       (skip-value? (caddr state)))
                   (cond
                    (skip-value?
                     [(cons arg out) index #f])
                    ((member arg +value-options+)
                     [(cons arg out) index #t])
                    ((or (member arg +boolean-flags+)
                         (string-prefix? "--" arg))
                     [(cons arg out) index #f])
                    (else
                     (let (next-index (fx1+ index))
                       (if (fx= next-index target-index)
                         [out next-index #f]
                         [(cons arg out) next-index #f]))))))
               ['() 0 #f]
               args))
    (reverse (car state))))

(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

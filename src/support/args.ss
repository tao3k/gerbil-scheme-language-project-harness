;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
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
;; ConfigConstant
(def +boolean-flags+ '("--json" "--code" "--names-only" "--changed" "--full" "--more"))
;; ConfigConstant
(def +value-options+
  '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"
    "--iterations" "--max-total-ms" "--whitelist"
    "--topic" "--intent" "--role" "--level" "--rule" "--finding" "--limit"))
;; Boolean <- Flag (List XX)
(def (flag? flag args)
  (member flag args))
;;; Invariant:
;;; - option owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Option <- Flag (List String)
(def (option flag args)
  (match args
    ([] #f)
    ([hd value . rest]
     (if (equal? hd flag) value (option flag (cons value rest))))
    ([_] #f)))
;;; Invariant:
;;; - options owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List String) <- Flag (List String)
(def (options flag args)
  (match args
    ([] '())
    ([hd value . rest]
     (if (equal? hd flag)
       (cons value (options flag rest))
       (options flag (cons value rest))))
    ([_] '())))
;;; Boundary:
;;; - positional-args composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- (List String)
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
;; ProjectRoot <- (List String)
(def (project-root args)
  (let (pos (positional-args args))
    (if (and (pair? pos) (file-directory? (last pos)))
      (last pos)
      ".")))
;; DropProjectRoot <- (List String)
(def (drop-project-root args)
  (let* ((pos (positional-args args))
         (root? (and (pair? pos) (file-directory? (last pos))))
         (root-index (and root? (length pos))))
    (if root?
      (drop-positional-index args root-index)
      args)))
;;; Boundary:
;;; - drop-positional-index composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- (List XX) TargetIndex
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
;;; Boundary:
;;; - file-directory? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String
(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

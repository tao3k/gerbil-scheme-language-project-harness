;;; -*- Gerbil -*-
;;; Agent-facing policy checks over facade intent comments.

(import :gerbil/gambit
        :parser
        :policy/model
        :policy/modularity
        :std/misc/ports
        :std/srfi/13
        :types/findings)

(export run-agent-policy
        facade-intent-finding)

(def (run-agent-policy index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (not (facade-has-intent-doc? index file))
          (facade-intent-finding file)))
   (project-index-files index)))

(def (facade-has-intent-doc? index file)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap intent-comment?
            (take* (read-file-lines
                    (path-expand (source-file-path file)
                                 (project-index-root index)))
                   8)))))

(def (intent-comment? line)
  (let (text (string-trim line))
    (and (string-prefix? ";;;" text)
         (not (string-contains text "-*-")))))

(def (facade-intent-finding file)
  (make-type-finding
   (policy-rule-id +agent-intent-rule+)
   (policy-rule-severity +agent-intent-rule+)
   (source-file-path file)
   (string-append "facade " (source-file-path file)
                  " lacks an agent-readable intent comment")
   (source-file-path file)
   #f))

(def (take* items count)
  (let lp ((rest items) (remaining count) (out '()))
    (cond
     ((or (null? rest) (fx<= remaining 0)) (reverse out))
     (else (lp (cdr rest) (fx1- remaining) (cons (car rest) out))))))

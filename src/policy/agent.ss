;;; -*- Gerbil -*-
;;; Agent-facing policy checks over facade intent comments.

(import :gerbil/gambit
        :parser/facade
        :policy/model
        :policy/modularity
        :std/misc/ports
        :std/srfi/13
        :types/findings)

(export run-agent-policy
        facade-intent-finding
        generic-owner-segment
        generic-owner-finding
        facade-export-conflict-findings)

(def +generic-owner-segments+
  '("utils" "common" "helpers" "shared"))

(def +generic-intent-comments+
  '("facade"
    "facade."
    "module"
    "module."
    "helper"
    "helper."
    "helpers"
    "helpers."
    "utility"
    "utility."
    "utilities"
    "utilities."
    "utility facade"
    "utility facade."
    "utilities facade"
    "utilities facade."
    "common facade"
    "common facade."
    "shared facade"
    "shared facade."
    "wrapper"
    "wrapper."))

(def (run-agent-policy index)
  (append
   (facade-intent-findings index)
   (facade-generic-intent-findings index)
   (generic-owner-findings index)
   (facade-export-conflict-findings index)))

(def (facade-intent-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (not (facade-has-intent-doc? index file))
          (facade-intent-finding file)))
   (project-index-files index)))

(def (generic-owner-findings index)
  (filter-map
   (lambda (file)
     (let (segment (generic-owner-segment (source-file-path file)))
       (and segment (generic-owner-finding file segment))))
   (project-index-files index)))

(def (facade-generic-intent-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (let (comment (facade-intent-comment index file))
            (and comment
                 (generic-intent-comment? comment)
                 (facade-generic-intent-finding file comment)))))
   (project-index-files index)))

(def (facade-has-intent-doc? index file)
  (not (not (facade-intent-comment index file))))

(def (facade-intent-comment index file)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (find intent-comment?
           (take* (read-file-lines
                   (path-expand (source-file-path file)
                                (project-index-root index)))
                  8)))))

(def (intent-comment? line)
  (let (text (string-trim line))
    (and (string-prefix? ";;;" text)
         (not (string-contains text "-*-")))))

(def (generic-intent-comment? line)
  (member (string-downcase (intent-comment-text line))
          +generic-intent-comments+))

(def (intent-comment-text line)
  (let (text (string-trim line))
    (if (string-prefix? ";;;" text)
      (string-trim (substring text 3 (string-length text)))
      text)))

(def (facade-intent-finding file)
  (make-type-finding
   (policy-rule-id +agent-intent-rule+)
   (policy-rule-severity +agent-intent-rule+)
   (source-file-path file)
   (string-append "facade " (source-file-path file)
                  " lacks an agent-readable intent comment")
   (source-file-path file)
   #f))

(def (generic-owner-segment path)
  (find (lambda (segment) (path-has-owner-segment? path segment))
        +generic-owner-segments+))

(def (path-has-owner-segment? path segment)
  (or (equal? path (string-append "src/" segment ".ss"))
      (string-contains path (string-append "/" segment ".ss"))
      (string-contains path (string-append "/" segment "/"))))

(def (generic-owner-finding file segment)
  (make-type-finding
   (policy-rule-id +agent-generic-owner-rule+)
   (policy-rule-severity +agent-generic-owner-rule+)
   (source-file-path file)
   (string-append "generic owner segment " segment
                  " hides the Gerbil module responsibility")
   (source-file-path file)
   (hash (segment segment))))

(def (facade-generic-intent-finding file comment)
  (make-type-finding
   (policy-rule-id +agent-generic-intent-rule+)
   (policy-rule-severity +agent-generic-intent-rule+)
   (source-file-path file)
   (string-append "facade " (source-file-path file)
                  " has a generic intent comment that does not describe the module responsibility")
   (source-file-path file)
   (hash (comment (intent-comment-text comment)))))

(def (facade-export-conflict-findings index)
  (let lp ((rest (facade-export-bindings index)) (seen '()) (out '()))
    (match rest
      ([binding . more]
       (let* ((name (car binding))
              (file (cdr binding))
              (prior (assoc name seen)))
         (cond
          ((and prior
                (not (equal? (source-file-path file)
                             (source-file-path (cdr prior)))))
           (lp more seen
               (cons (export-conflict-finding name file (cdr prior)) out)))
          (else
           (lp more (cons binding seen) out)))))
      (else (reverse out)))))

(def (facade-export-bindings index)
  (apply append
         (map (lambda (file)
                (if (facade-source-file? index file)
                  (map (lambda (name) (cons name file))
                       (source-file-exports file))
                  '()))
              (project-index-files index))))

(def (export-conflict-finding name file prior)
  (make-type-finding
   (policy-rule-id +agent-export-conflict-rule+)
   (policy-rule-severity +agent-export-conflict-rule+)
   (source-file-path file)
   (string-append "facade export " name
                  " conflicts with another facade export")
   (source-file-path file)
   (hash (export name)
         (firstPath (source-file-path prior))
         (duplicatePath (source-file-path file)))))

(def (take* items count)
  (let lp ((rest items) (remaining count) (out '()))
    (cond
     ((or (null? rest) (fx<= remaining 0)) (reverse out))
     (else (lp (cdr rest) (fx1- remaining) (cons (car rest) out))))))

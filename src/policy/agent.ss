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
        vague-definition-finding
        top-level-executable-finding
        poo-direct-writeenv-finding
        poo-io-runtime-witness-finding
        facade-export-conflict-findings)

(def +generic-owner-segments+
  '("utils" "util" "utility" "common" "helpers" "misc" "shared"))

(def +vague-definition-names+
  '("helper" "helpers" "process" "handle" "convert" "transform" "thing" "stuff" "do-it" "run-it"))

(def +poo-declarative-heads+
  '("defclass" ".defclass" ".defgeneric" "defmethod" ".defmethod"))

(def (run-agent-policy index)
  (append
   (facade-intent-findings index)
   (generic-owner-findings index)
   (vague-definition-findings index)
   (top-level-executable-findings index)
   (poo-direct-writeenv-findings index)
   (poo-io-runtime-witness-findings index)
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

(def (vague-definition-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (definition)
                   (and (vague-definition-name? (definition-name definition))
                        (vague-definition-finding file definition)))
                 (source-file-definitions file)))
              (project-index-files index))))

(def (vague-definition-name? name)
  (member name +vague-definition-names+))

(def (vague-definition-finding file definition)
  (make-type-finding
   (policy-rule-id +agent-vague-definition-rule+)
   (policy-rule-severity +agent-vague-definition-rule+)
   (source-file-path file)
   (string-append "definition " (definition-name definition)
                  " is too vague for agent-written Gerbil; name the domain or data flow")
   (definition-selector definition)
   (hash (definition (definition-name definition))
         (selector (definition-selector definition)))))

(def (top-level-executable-findings index)
  (apply append
         (map (lambda (file)
              (filter-map
               (lambda (call)
                   (and (top-level-executable-call? file call)
                        (top-level-executable-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))

(def (top-level-executable-call? file call)
  (and (not (call-fact-caller call))
       (source-runtime-file-path? (call-fact-path call))
       (not (poo-declarative-call? file call))))

(def (poo-declarative-call? file call)
  (and (poo-source-file? file)
       (ormap (lambda (form)
                (and (member (top-form-head form) +poo-declarative-heads+)
                     (equal? (top-form-selector form)
                             (call-fact-selector call))))
              (source-file-forms file))))

(def (poo-source-file? file)
  (ormap (lambda (import)
           (string-contains import "clan/poo"))
         (source-file-imports file)))

(def (source-runtime-file-path? path)
  (and (string-prefix? "src/" path)
       (string-suffix? ".ss" path)))

(def (top-level-executable-finding file call)
  (make-type-finding
   (policy-rule-id +agent-top-level-executable-rule+)
   (policy-rule-severity +agent-top-level-executable-rule+)
   (source-file-path file)
   (string-append "top-level executable call " (call-fact-callee call)
                  " should move behind a named definition or explicit entrypoint")
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))

(def (poo-direct-writeenv-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (and (direct-writeenv-call? call)
                        (poo-direct-writeenv-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))

(def (direct-writeenv-call? call)
  (equal? (call-fact-callee call) "writeenv"))

(def (poo-direct-writeenv-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-direct-writeenv-rule+)
   (policy-rule-severity +agent-poo-direct-writeenv-rule+)
   (source-file-path file)
   "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first"
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))

(def (poo-io-runtime-witness-findings index)
  (filter-map
   (lambda (file)
     (and (source-runtime-file-path? (source-file-path file))
          (poo-io-source-file? file)
          (poo-io-method-override-file? file)
          (poo-io-runtime-witness-finding file)))
   (project-index-files index)))

(def (poo-io-source-file? file)
  (ormap poo-io-import? (source-file-imports file)))

(def (poo-io-import? import)
  (or (equal? import ":clan/poo/io")
      (equal? import "clan/poo/io")
      (string-contains import "clan/poo/io")))

(def (poo-io-method-override-file? file)
  (or (ormap (lambda (form)
               (member (top-form-head form)
                       ["defmethod" ".defmethod"]))
             (source-file-forms file))
      (ormap (lambda (call)
               (member (call-fact-callee call)
                       ["defmethod" ".defmethod"]))
             (source-file-calls file))))

(def (poo-io-runtime-witness-finding file)
  (make-type-finding
   (policy-rule-id +agent-poo-io-runtime-witness-rule+)
   (policy-rule-severity +agent-poo-io-runtime-witness-rule+)
   (source-file-path file)
   "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified"
   (source-file-path file)
   (hash (next "search runtime-source writeenv printer hook")
         (requiredWitness "writeenv-roundtrip-witness"))))

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

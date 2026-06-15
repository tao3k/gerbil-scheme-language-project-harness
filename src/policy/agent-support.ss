;;; -*- Gerbil -*-
;;; Shared helpers for agent-facing policy rule families.

(import :parser/facade
        (only-in :std/srfi/13 string-contains string-prefix? string-suffix?)
        (only-in :std/sugar ormap)
        :support/list)

(export +poo-declarative-heads+
        +poo-capability-dependencies+
        poo-source-file?
        poo-capability-active?
        poo-capability-dependency?
        source-runtime-file-path?
        index-source-runtime-file-path?
        explicit-runtime-entrypoint-path?
        configured-runtime-roots
        source-path-under-root?
        project-poo-forms
        poo-class-fact-exists?
        poo-protocol-fact-exists?
        blank-string?
        join-missing)
;; ConfigConstant
(def +poo-declarative-heads+
  '(".def" "define-type" "defclass" ".defclass" ".defgeneric" "defmethod" ".defmethod"))
;; Integer
(def +poo-capability-dependencies+
  '("gerbil-poo" "clan/poo"))
;;; Boundary:
;;; - poo-source-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- SourceFile
(def (poo-source-file? file)
  (ormap (lambda (import)
           (string-contains import "clan/poo"))
         (source-file-imports file)))
;;; Boundary:
;;; - poo-capability-active? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex
(def (poo-capability-active? index)
  (or (ormap poo-source-file? (project-index-files index))
      (ormap (lambda (fact)
               (member (poo-form-fact-role fact)
                       '("class" "generic" "method")))
             (project-poo-forms index))
      (let (package (project-index-package index))
        (and package
             (ormap poo-capability-dependency?
                    (project-package-dependencies package))))))
;;; Boundary:
;;; - poo-capability-dependency? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String
(def (poo-capability-dependency? dependency)
  (ormap (lambda (needle)
           (string-contains dependency needle))
         +poo-capability-dependencies+))
;; Boolean <- String
(def (source-runtime-file-path? path)
  (and (string-prefix? "src/" path)
       (string-suffix? ".ss" path)))
;; Boolean <- String
(def (explicit-runtime-entrypoint-path? path)
  (and (string-prefix? "src/search-fast/" path)
       (string-suffix? ".ss" path)))
;;; Boundary:
;;; - index-source-runtime-file-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex String
(def (index-source-runtime-file-path? index path)
  (and (string-suffix? ".ss" path)
       (let* ((package (project-index-package index))
              (policy (and package
                           (project-package-source-scope-policy package)))
              (roots (configured-runtime-roots policy)))
         (ormap (lambda (root)
                  (source-path-under-root? path root))
                roots))))
;; (List String) <- Policy
(def (configured-runtime-roots policy)
  (cond
   ((and policy (pair? (source-scope-policy-runtime-roots policy)))
    (source-scope-policy-runtime-roots policy))
   ((and policy (pair? (source-scope-policy-roots policy)))
    (source-scope-policy-roots policy))
   (else ["src"])))
;; Boolean <- String String
(def (source-path-under-root? path root)
  (or (equal? root ".")
      (equal? path root)
      (string-prefix? (string-append root "/") path)))
;;; Boundary:
;;; - project-poo-forms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- ProjectIndex
(def (project-poo-forms index)
  (apply append (map source-file-poo-forms (project-index-files index))))
;;; Boundary:
;;; - poo-class-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex ClassName
(def (poo-class-fact-exists? index class-name)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "class")
          (equal? (poo-form-fact-name fact) class-name)))
   (project-poo-forms index)))
;;; Boundary:
;;; - poo-protocol-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex ProtocolName
(def (poo-protocol-fact-exists? index protocol-name)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "protocol")
          (equal? (poo-form-fact-name fact) protocol-name)))
   (project-poo-forms index)))
;; Boolean <- MaybeString
(def (blank-string? value)
  (or (not value) (equal? value "")))
;;; Invariant:
;;; - join-missing owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; JoinMissing <- (List XX)
(def (join-missing items)
  (join items ","))

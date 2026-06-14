;;; -*- Gerbil -*-
;;; Gerbil-poo package extension facts activated by declared gxpkg dependencies.
;;; Boundary:
;;; - Owns direct gerbil-poo activation from gerbil.pkg dependencies.
;;; - Delegates inherited gerbil-utils pattern facts to poo-inheritance.

(import :extensions/model
        :extensions/poo-inheritance
        :extensions/poo-patterns
        :package-manager/facade
        :parser/facade
        :std/sugar
        :support/list)

(export poo-extension-active?
        poo-extension-fact
        poo-registered-extension-facts
        poo-registered-extension-query?
        poo-extension-capability-names
        poo-extension-search-lines
        poo-extension-json
        poo-source-ref
        poo-pattern-evidence
        poo-pattern-query?
        poo-pattern-focus
        poo-pattern-kind
        poo-pattern-selectors
        poo-pattern-minimal-forms
        poo-pattern-failure-cases)
;; ConfigConstant
(def +poo-extension-name+ "poo")
;; ConfigConstant
(def +poo-extension-activation+ "gerbil.pkg")
;; Integer
(def +poo-dependency-mode+ "required")
;; ConfigConstant
(def +poo-package-tokens+
  '("poo" "clan/poo" "gerbil-poo" "git.cons.io/mighty-gerbils/gerbil-poo"))
;; ConfigConstant
(def +poo-registered-dependency+ "git.cons.io/mighty-gerbils/gerbil-poo")
;; ConfigConstant
(def +poo-registered-package+ "gerbil-poo://registry")
;; Boolean <- ProjectIndex
(def (poo-extension-active? index)
  (project-package-depends-on? (project-index-package index)
                               poo-package-token?))
;; Boolean <- String
(def (poo-package-token? token)
  (and token
       (or (member token +poo-package-tokens+)
           (string-suffix? "/gerbil-poo" token))))
;; (List String)
(def (poo-extension-capability-names)
  (append '("object-system"
            "metaobject-protocol"
            "protocols"
            "policy-protocol"
            "macro-governance"
            "user-override-witness")
          (poo-inherited-utils-capability-names)))
;; Fact <- ProjectIndex
(def (poo-extension-fact index)
  (and (poo-extension-active? index)
       (let (package (project-index-package index))
         (make-extension-fact +poo-extension-name+
                              +poo-extension-activation+
                              +poo-dependency-mode+
                              (project-package-manager package)
                              (project-package-name package)
                              (project-package-dependencies package)
                              (poo-extension-capability-names)))))
;; (List ExtensionFact) <- (List SearchTerm)
(def (poo-registered-extension-facts terms)
  (if (poo-registered-extension-query? terms)
    [(poo-registered-extension-fact)]
    '()))
;;; Query guard:
;;; - ormap keeps registered dependency recall as a term-level predicate.
;;; - Empty queries never synthesize ambient registry facts.
;; Boolean <- (List SearchTerm)
(def (poo-registered-extension-query? terms)
  (and (pair? terms)
       (ormap poo-registered-extension-token? terms)))
;; Boolean <- SearchTerm
(def (poo-registered-extension-token? term)
  (and term
       (or (equal? term "gerbil-poo")
           (equal? term +poo-registered-dependency+))))
;; ExtensionFact
(def (poo-registered-extension-fact)
  (make-extension-fact +poo-extension-name+
                       "gerbil-poo://"
                       "registered"
                       "gxpkg"
                       +poo-registered-package+
                       [+poo-registered-dependency+]
                       (poo-extension-capability-names)))
;; (List String) <- ProjectIndex
(def (poo-extension-search-lines index)
  (let (fact (poo-extension-fact index))
    (if fact
      [(extension-fact-search-line fact)]
      '())))
;; Json <- ProjectIndex
(def (poo-extension-json index)
  (let (fact (poo-extension-fact index))
    (and fact (extension-fact-json fact))))
;; PooSourceRef <- ProjectIndex
(def (poo-source-ref index)
  (hash (kind "package-manager-download")
        (manager "gxpkg")
        (package +poo-extension-name+)
        (dependency (poo-extension-dependency index))
        (repository "git.cons.io/mighty-gerbils/gerbil-poo")
        (pathPolicy "runtime-resolved")
        (selectorScheme "gerbil-poo-logical-symbol")))
;;; Boundary:
;;; - poo-extension-dependency composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- ProjectIndex
(def (poo-extension-dependency index)
  (let* ((package (project-index-package index))
         (matches (if package
                    (filter poo-package-token?
                            (project-package-dependencies package))
                    '())))
    (if (pair? matches)
      (car matches)
      +poo-registered-dependency+)))
;;; Dispatch boundary:
;;; - Direct POO patterns and inherited utility patterns share one packet schema.
;;; - Keep activation proof here so inherited facts cannot appear ambiently.
;; String <- ProjectIndex (List PooFormFact)
(def (poo-pattern-evidence index terms)
  (let* ((poo-query? (poo-pattern-query? terms))
         (inherited-query? (poo-inherited-utils-pattern-query? terms))
         (extension-fact (poo-extension-fact index))
         (registered-query? (poo-registered-extension-query? terms)))
    (and (or poo-query? inherited-query?)
         (or extension-fact registered-query?)
         (if inherited-query?
           (poo-inherited-utils-pattern-evidence
            (poo-extension-dependency index)
            terms)
           (let (kind (poo-pattern-kind terms))
             (hash (id (poo-pattern-id kind))
                   (extension +poo-extension-name+)
                   (focus (poo-pattern-focus kind terms))
                   (origin (if extension-fact "direct" "registered"))
                   (sourceRef (poo-source-ref index))
                   (sourceOwners (poo-pattern-source-owners kind))
                   (selectors (poo-pattern-selectors kind))
                   (agentScenario (poo-pattern-agent-scenario kind))
                   (intent (poo-pattern-intent kind))
                   (minimalForms (poo-pattern-minimal-forms kind))
                   (failureCases (poo-pattern-failure-cases kind))
                   (qualitySignals
                    (poo-pattern-quality-signals-for-origin
                     kind
                     extension-fact))
                   (agentSteering (poo-pattern-agent-steering kind))
                   (witness (poo-pattern-witness kind))
                   (missing (poo-pattern-missing kind))
                   (next (poo-pattern-next-for-origin
                          kind
                          terms
                          extension-fact))))))))
;; Boolean <- (List PooFormFact)
(def (poo-pattern-query? terms)
  (and (pair? terms)
       (or (equal? (car terms) +poo-extension-name+)
           (member +poo-extension-name+ terms)
           (poo-registered-extension-query? terms))))
;;; Classification boundary:
;;; - Terms map agent language onto provider-owned POO pattern families.
;;; - Keep aliases broad enough for search but route output through fixed ids.
;; String <- (List PooFormFact)
(def (poo-pattern-kind terms)
  (cond
   ((poo-pattern-term-any? terms ["rationaldict" "dependency-adapter"
                                  "dependency-protocol-adapter"
                                  "protocol-adapter" "adapter-quality"])
    'dependency-protocol-adapter)
   ((poo-pattern-term-any? terms ["trace" "debug" "trace-poo"
                                  "trace-inherited-slot" "traced-function"])
    'trace-debug)
   ((poo-pattern-term-any? terms ["json" "print" "sexp" "io" "write-json"
                                  "serialization" "fallback"])
    'io-json-fallback)
   ((poo-pattern-term-any? terms ["lens" "slot-lens"])
    'lens)
   ((poo-pattern-term-any? terms ["sealed" "validate" "validation"
                                  "element?" "type-validation"])
    'type-validation)
   ((poo-pattern-term-any? terms ["c3" "mro" "linearization"
                                  "precedence" "slot-order"])
    'c3-mro)
   ((poo-pattern-term-any? terms ["cache" "cached" ".ref" ".ref/cached"
                                  "computed" "apply-slot-spec" "superfun"])
    'slot-cache)
   ((poo-pattern-term-any? terms ["proto" "prototype" "compose-proto"
                                  "compose-proto*" "instantiate-proto"])
    'prototype-composition)
   (else 'object-system)))
;;; Boundary:
;;; - poo-pattern-term-any? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- (List PooFormFact) Needles
(def (poo-pattern-term-any? terms needles)
  (and (pair? terms)
       (ormap (lambda (needle) (member needle terms)) needles)))
;;; Origin projection:
;;; - Active extension packets keep all source-backed quality signals.
;;; - Registered-only packets replace activation proof with logical selector evidence.
;;; - filter preserves the remaining signal order so snapshots stay stable.
;; (List String) <- Kind MaybeExtensionFact
(def (poo-pattern-quality-signals-for-origin kind extension-fact)
  (let (signals (poo-pattern-quality-signals kind))
    (if extension-fact
      signals
      (cons "gerbil-poo-logical-selector-registry"
            (filter (lambda (signal)
                      (not (equal? signal "active-extension-fact")))
                    signals)))))
;; String <- Kind PatternTerms MaybeExtensionFact
(def (poo-pattern-next-for-origin kind terms extension-fact)
  (if extension-fact
    (poo-pattern-next kind)
    (string-append "search extension gerbil-poo "
                   (poo-pattern-focus kind terms))))

;; Boolean <- Suffix SourceLine
(def (string-suffix? suffix text)
  (let ((suffix-length (string-length suffix))
        (text-length (string-length text)))
    (and (fx<= suffix-length text-length)
         (equal? suffix
                 (substring text (fx- text-length suffix-length) text-length)))))

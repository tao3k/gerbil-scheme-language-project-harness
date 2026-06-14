;;; -*- Gerbil -*-
;;; Compact search renderer helpers for agent-facing source evidence.

(import :parser/source-class
        :support/list)

(export emit-selector-resolver-line
        emit-source-example-line
        emit-source-comment-line
        emit-structural-syntax-fact-lines
        detail-list
        join-or-dash)
;; Integer
(def +syntax-fact-render-limit+ 32)
;; Selector <- Resolver
(def (emit-selector-resolver-line resolver)
  (displayln "|selectorResolver scheme=" (hash-get resolver 'scheme)
             " owner=" (hash-get resolver 'owner)
             " stateNamespace=" (hash-get resolver 'stateNamespace)
             " versionKey=" (hash-get resolver 'versionKey)
             " selectorFormat=" (hash-get resolver 'selectorFormat)
             " output=" (hash-get resolver 'output)
             " indexOwner=" (hash-get resolver 'indexOwner)))
;; String <- Example
(def (emit-source-example-line example)
  (let (form (hash-get example 'form))
    (displayln "|sourceExample id=" (hash-get example 'id)
               " role=" (hash-get example 'role)
               " symbol=" (hash-get example 'symbol)
               " selector=" (hash-get example 'selector)
               " head=" (hash-get form 'head)
               " operands=" (join-or-dash (hash-get form 'operands))
               " keywords=" (join-or-dash (hash-get form 'keywords))
               " commentMode=" (hash-get example 'commentMode))))
;; String <- Comment
(def (emit-source-comment-line comment)
  (displayln "|sourceComment id=" (hash-get comment 'id)
             " selector=" (hash-get comment 'selector)
             " extractor=" (hash-get comment 'extractor)
             " summary=" (hash-get comment 'summary)
             " fallback=" (hash-get comment 'fallback)))
;; Unit <- (List SyntaxFact)
(def (emit-structural-syntax-fact-lines facts)
  (for-each emit-syntax-fact-line
            (ranked-syntax-facts facts)))
;;; Boundary:
;;; - emit-syntax-fact-line coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; Unit <- SyntaxFact
(def (emit-syntax-fact-line fact)
  (let* ((fields (hash-get fact 'fields))
         (location (hash-get fact 'location)))
    (displayln "|syntaxFact kind=" (hash-get fact 'kind)
               " languageKind=" (hash-get fact 'languageKind)
               " name=" (hash-get fact 'name)
               " owner=" (hash-get fact 'ownerPath)
               " range=" (hash-get location 'lineRange)
               " sourceClass=" (source-path-class (hash-get fact 'ownerPath))
               " role=" (field-string fields 'role)
               " generic=" (field-string fields 'generic)
               " receiver=" (field-string fields 'receiver)
               " receiverType=" (field-string fields 'receiverType)
               " supers=" (field-list-string fields 'supers)
               " slots=" (field-list-string fields 'slots)
               " options=" (field-list-string fields 'options)
               " specializers=" (field-list-string fields 'specializers)
               " dispatchArity=" (field-string fields 'dispatchArity)
               " operandCount=" (field-string fields 'operandCount)
               " arities=" (field-list-string fields 'arities)
               " formals=" (field-list-string fields 'formals)
               " caller=" (field-string fields 'caller)
               " dependency=" (field-string fields 'dependency)
               " importedSymbols=" (field-list-string fields 'importedSymbols)
               " usedSymbols=" (field-list-string fields 'usedSymbols)
               " protocolRefs=" (field-list-string fields 'protocolRefs)
               " derivedCapabilities=" (field-list-string fields 'derivedCapabilities)
               " manualObjectEncodingRisk=" (field-string fields 'manualObjectEncodingRisk)
               " genericContractWitnessKind=" (field-string fields 'genericContractWitnessKind)
               " contract=" (field-string fields 'contract)
               " contractOutput=" (field-string fields 'contractOutput)
               " contractInputs=" (field-list-string fields 'contractInputs)
               " definitionArity=" (field-string fields 'definitionArity)
               " arityAlignment=" (field-string fields 'arityAlignment)
               " targetKind=" (field-string fields 'targetKind)
               " context=" (field-string fields 'context)
               " commentKind=" (field-string fields 'commentKind)
               " required=" (field-string fields 'required)
               " quality=" (field-string fields 'quality)
               " reasons=" (field-list-string fields 'reasons)
               " commentLines=" (field-list-string fields 'commentLines)
               " tokens=" (field-list-string fields 'tokens)
               " arrowCount=" (field-string fields 'arrowCount)
               " groupCount=" (field-string fields 'groupCount))))
;;; Boundary:
;;; - ranked-syntax-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List SyntaxFact) <- (List SyntaxFact)
(def (ranked-syntax-facts facts)
  (reverse
   (ranked-syntax-state-output
    (foldl (lambda (predicate state)
             (select-ranked-syntax-facts facts predicate state))
           ['() '() +syntax-fact-render-limit+]
           (ranked-syntax-fact-predicates)))))

;;; Boundary:
;;; - ranked-syntax-fact-predicates composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List SyntaxFactPredicate)
(def (ranked-syntax-fact-predicates)
  [poo-syntax-fact?
   dependency-adapter-quality-syntax-fact?
   invalid-typed-contract-syntax-fact?
   higher-order-syntax-fact?
   typed-contract-syntax-fact?
   weak-comment-quality-syntax-fact?
   comment-quality-syntax-fact?
   macro-or-import-syntax-fact?
   (lambda (_) #t)])

;;; Invariant:
;;; - ranked-syntax-state-output owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; SyntaxFactList <- RankedSyntaxState
(def (ranked-syntax-state-output state)
  (match state
    ([seen out remaining] out)))

;;; Boundary:
;;; - select-ranked-syntax-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; RankedSyntaxState <- (List SyntaxFact) SyntaxFactPredicate RankedSyntaxState
(def (select-ranked-syntax-facts facts predicate state)
  (foldl (lambda (fact state)
           (select-ranked-syntax-fact predicate fact state))
         state
         facts))

;;; Invariant:
;;; - select-ranked-syntax-fact owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; RankedSyntaxState <- SyntaxFactPredicate SyntaxFact RankedSyntaxState
(def (select-ranked-syntax-fact predicate fact state)
  (match state
    ([seen out remaining]
     (let (id (hash-get fact 'id))
       (if (ranked-syntax-fact-selected? predicate seen remaining fact)
         [(cons id seen) (cons fact out) (- remaining 1)]
         state)))))

;; Boolean <- SyntaxFactPredicate (List SyntaxFactId) Integer SyntaxFact
(def (ranked-syntax-fact-selected? predicate seen remaining fact)
  (and (> remaining 0)
       (predicate fact)
       (not (member (hash-get fact 'id) seen))))

;;; Predicate selectors share the same syntax field accessor so role and
;;; quality checks stay expression-level instead of re-opening the fields hash
;;; in each predicate branch.
;; String <- SyntaxFact Key
(def (syntax-fact-field-string fact key)
  (field-string (hash-get fact 'fields) key))

;; Boolean <- SyntaxFact Key (List String)
(def (syntax-fact-field-member? fact key values)
  (member (syntax-fact-field-string fact key) values))

;; Boolean <- SyntaxFact Key String
(def (syntax-fact-field=? fact key expected)
  (equal? (syntax-fact-field-string fact key) expected))

;; Boolean <- SyntaxFact Key (List String)
(def (syntax-fact-value-member? fact key values)
  (member (hash-get fact key) values))

;; Boolean <- SyntaxFact
(def (poo-syntax-fact? fact)
  (syntax-fact-field-member? fact 'role '("class" "generic" "protocol" "method")))
;; Boolean <- SyntaxFact
(def (dependency-adapter-quality-syntax-fact? fact)
  (syntax-fact-field=? fact 'role "dependency-protocol-adapter"))
;; Boolean <- SyntaxFact
(def (macro-or-import-syntax-fact? fact)
  (syntax-fact-value-member? fact 'kind '("macro" "import")))
;; Boolean <- SyntaxFact
(def (higher-order-syntax-fact? fact)
  (syntax-fact-field-member? fact 'role
                             '("anonymous-function"
                               "multi-arity-function"
                               "partial-application"
                               "loop-fold"
                               "sequence-map"
                               "sequence-filter"
                               "sequence-fold")))
;; Boolean <- SyntaxFact
(def (typed-contract-syntax-fact? fact)
  (syntax-fact-field=? fact 'role "typed-combinator-style"))
;; Boolean <- SyntaxFact
(def (invalid-typed-contract-syntax-fact? fact)
  (and (typed-contract-syntax-fact? fact)
       (syntax-fact-field=? fact 'quality "invalid")))
;; Boolean <- SyntaxFact
(def (comment-quality-syntax-fact? fact)
  (syntax-fact-field=? fact 'role "engineering-comment-quality"))
;; Boolean <- SyntaxFact
(def (weak-comment-quality-syntax-fact? fact)
  (and (comment-quality-syntax-fact? fact)
       (syntax-fact-field-member? fact 'quality '("absent" "weak"))))
;; String <- Fields Key
(def (field-string fields key)
  (if (and fields (hash-key? fields key))
    (dash-empty (value->field-string (hash-get fields key)))
    "-"))
;;; Boundary:
;;; - field-list-string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Fields Key
(def (field-list-string fields key)
  (if (and fields (hash-key? fields key))
    (let (value (hash-get fields key))
      (cond
       ((list? value) (join-or-dash (map value->field-string value)))
       ((string? value) (dash-empty value))
       (else "-")))
    "-"))
;; DashEmpty <- Value
(def (dash-empty value)
  (cond
   ((not value) "-")
   ((and (string? value) (fx= (string-length value) 0)) "-")
   (else value)))
;; String <- FieldValue
(def (value->field-string value)
  (cond
   ((number? value) (number->string value))
   ((boolean? value) (if value "true" "false"))
   (else value)))
;; DetailList <- Details Key
(def (detail-list details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))
;; JoinOrDash <- Values
(def (join-or-dash values)
  (if (null? values)
    "-"
    (join values ",")))

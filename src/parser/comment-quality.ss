;;; -*- Gerbil -*-
;;; Parser-owned engineering comment quality facts.

(import :gerbil/gambit
        :parser/model
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13 string-contains string-downcase string-prefix?)
        (only-in :std/sugar cut filter find hash ormap while)
        :support/list)

(export comment-quality-facts-from-source)

;;; Boundary:
;;; - comment-quality-facts-from-source composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List CommentQualityFact) <- FullPath Relpath (List Definition) (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact)
(def (comment-quality-facts-from-source fullpath relpath definitions macros poo-forms higher-order-forms control-flow-forms)
  (let* ((lines (read-file-lines fullpath))
         (module-fact (module-comment-quality-fact relpath lines)))
    (cons module-fact
          (map (cut definition-comment-quality-fact
                    relpath lines <> macros poo-forms
                    higher-order-forms control-flow-forms)
               definitions))))

;; CommentQualityFact <- Relpath (List SourceLine)
(def (module-comment-quality-fact relpath lines)
  (let* ((comments (module-leading-comments lines))
         (summary (comment-quality-summary comments #t "module")))
    (make-comment-quality-fact
     "module" relpath relpath 1 1
     1 (max 1 (length comments))
     comments
     (vector-ref summary 0)
     (vector-ref summary 1)
     (vector-ref summary 2)
     #t
     "module"
     (module-comment-quality-evidence relpath lines comments))))

;;; Boundary:
;;; - definition-comment-quality-fact coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; CommentQualityFact <- Relpath (List SourceLine) Definition (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact)
(def (definition-comment-quality-fact relpath lines definition macros poo-forms higher-order-forms control-flow-forms)
  (let* ((comments (leading-comment-lines lines (definition-start definition)))
         (context (definition-comment-context definition macros poo-forms higher-order-forms control-flow-forms))
         (required (definition-comment-required? definition context))
         (summary (comment-quality-summary comments required context))
         (comment-start (if (null? comments)
                          (definition-start definition)
                          (- (definition-start definition)
                             (length comments))))
         (evidence (definition-comment-quality-evidence
                     definition context macros poo-forms
                     higher-order-forms control-flow-forms comments)))
    (make-comment-quality-fact
     "definition"
     (definition-name definition)
     relpath
     (definition-start definition)
     (definition-end definition)
     comment-start
     (if (null? comments)
       (definition-start definition)
       (fx1- (definition-start definition)))
     comments
     (vector-ref summary 0)
     (vector-ref summary 1)
     (vector-ref summary 2)
     required
     context
     evidence)))

;; Json <- Relpath (List SourceLine) (List CommentLine)
(def (module-comment-quality-evidence relpath lines comments)
  (hash (factSource "native-parser")
        (targetKind "module")
        (path relpath)
        (lineCount (length lines))
        (existingCommentLines comments)
        (existingCommentLineCount (length comments))
        (matchedFacts [])
        (commentFocus (comment-quality-context-focus "module"))
        (commentQuestions (comment-quality-context-questions "module"))
        (agentRepairMode "generate as many adjacent engineering comment lines as needed from parser evidence; completeness and confidence matter more than line count")))

;; Json <- Definition String (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) (List CommentLine)
(def (definition-comment-quality-evidence definition context macros poo-forms higher-order-forms control-flow-forms comments)
  (let (matched-facts
        (definition-comment-matched-facts
          definition macros poo-forms higher-order-forms control-flow-forms))
    (hash (factSource "native-parser")
          (targetKind "definition")
          (definition (definition-name definition))
          (definitionKind (definition-kind definition))
          (definitionFormals (definition-formals definition))
          (definitionArity (definition-arity definition))
          (lineSpan (definition-line-span definition))
          (selector (definition-source-selector definition))
          (context context)
          (existingCommentLines comments)
          (existingCommentLineCount (length comments))
          (matchedFactCount (length matched-facts))
          (matchedFacts matched-facts)
          (commentFocus (comment-quality-context-focus context))
          (commentQuestions (comment-quality-context-questions context))
          (agentRepairMode "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale"))))

;;; Parser witness join: preserve owner/caller keyed joins so R015 can expose concrete macro, POO, higher-order, and control-flow evidence without source scanning.
;; (List Json) <- Definition (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact)
(def (definition-comment-matched-facts definition macros poo-forms higher-order-forms control-flow-forms)
  (let (name (definition-name definition))
     (append
      (map macro-comment-evidence
          (take-at-most (matching-macro-facts name macros) 4))
      (map poo-comment-evidence
          (take-at-most (matching-poo-facts name poo-forms) 4))
      (map higher-order-comment-evidence
          (take-at-most (matching-higher-order-facts name higher-order-forms) 6))
      (map control-flow-comment-evidence
          (take-at-most (matching-control-flow-facts name control-flow-forms) 4)))))

;;; Parser-owned macro evidence is joined by definition name.
;;; Do not widen this into comment text or selector substring matching.
;; (List MacroFact) <- String (List MacroFact)
(def (matching-macro-facts name facts)
  (filter (lambda (fact) (equal? (macro-fact-name fact) name))
          facts))

;;; POO evidence is joined by object/generic/protocol form name so comment repair can cite the declared language feature boundary.
;; (List PooFormFact) <- String (List PooFormFact)
(def (matching-poo-facts name facts)
  (filter (lambda (fact) (equal? (poo-form-fact-name fact) name))
          facts))

;;; Higher-order evidence is joined by caller, which preserves the expression-level combinator witness for comment generation.
;; (List HigherOrderFact) <- String (List HigherOrderFact)
(def (matching-higher-order-facts name facts)
  (filter (lambda (fact) (equal? (higher-order-fact-caller fact) name))
          facts))

;;; Control-flow evidence is joined by caller so loop, match, continuation, and resource-driver comments stay tied to parsed facts.
;; (List ControlFlowFact) <- String (List ControlFlowFact)
(def (matching-control-flow-facts name facts)
  (filter (lambda (fact) (equal? (control-flow-fact-caller fact) name))
          facts))

;; Json <- MacroFact
(def (macro-comment-evidence fact)
  (hash (factKind "macro")
        (name (macro-fact-name fact))
        (formKind (macro-fact-kind fact))
        (transformer (macro-fact-transformer fact))
        (phase (macro-fact-phase fact))
        (patternCount (macro-fact-pattern-count fact))
        (hygienicSyntax (macro-fact-hygienic fact))
        (qualityFacets (macro-fact-quality-facets fact))
        (selector (fact-source-selector (macro-fact-path fact)
                                        (macro-fact-start fact)
                                        (macro-fact-end fact)))))

;; Json <- PooFormFact
(def (poo-comment-evidence fact)
  (hash (factKind "poo")
        (name (poo-form-fact-name fact))
        (formKind (poo-form-fact-kind fact))
        (role (poo-form-fact-role fact))
        (generic (or (poo-form-fact-generic fact) ""))
        (receiver (or (poo-form-fact-receiver fact) ""))
        (receiverType (or (poo-form-fact-receiver-type fact) ""))
        (supers (poo-form-fact-supers fact))
        (slots (poo-form-fact-slots fact))
        (specializers (poo-form-fact-specializers fact))
        (specializerTypes (poo-form-fact-specializer-types fact))
        (selector (fact-source-selector (poo-form-fact-path fact)
                                        (poo-form-fact-start fact)
                                        (poo-form-fact-end fact)))))

;; Json <- HigherOrderFact
(def (higher-order-comment-evidence fact)
  (hash (factKind "higher-order")
        (name (higher-order-fact-name fact))
        (formKind (higher-order-fact-kind fact))
        (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (arities (higher-order-fact-arities fact))
        (formals (higher-order-fact-formals fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (selector (fact-source-selector (higher-order-fact-path fact)
                                        (higher-order-fact-start fact)
                                        (higher-order-fact-end fact)))))

;; Json <- ControlFlowFact
(def (control-flow-comment-evidence fact)
  (hash (factKind "control-flow")
        (name (control-flow-fact-name fact))
        (formKind (control-flow-fact-kind fact))
        (role (control-flow-fact-role fact))
        (caller (or (control-flow-fact-caller fact) ""))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (selector (fact-source-selector (control-flow-fact-path fact)
                                        (control-flow-fact-start fact)
                                        (control-flow-fact-end fact)))))

;; String <- String
(def (comment-quality-context-focus context)
  (cond
   ((equal? context "module")
    "module responsibility, public boundary, package/import/export assumptions, and parser/policy ownership")
   ((equal? context "macro")
    "macro expansion boundary, hygiene assumptions, runtime-source witness, and safe edit constraints")
   ((equal? context "poo")
    "object/protocol/generic invariant, method specializers, and runtime witness boundary")
   ((equal? context "higher-order")
    "expression-level data flow, combinator choice, arity shape, and why the transform is safe")
   ((equal? context "control-flow")
    "state/control driver, branch invariants, loop or continuation reason, and exit conditions")
   ((equal? context "long-definition")
    "large-owner responsibility, branch/risk boundary, and intended optimization or decomposition pressure")
   (else
    "definition purpose, stable invariant, and non-obvious edit boundary")))

;;; Boundary:
;;; - comment-quality-context-questions coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;;; Agent repair contract: each context question names the parser evidence a model must cover before writing rationale.
;; (List String) <- String
(def (comment-quality-context-questions context)
  (cond
   ((equal? context "module")
    ["What responsibility does this module own for the harness?"
     "Which package/import/export or runtime boundary must future edits preserve?"
     "Which parser-owned facts or policy outputs should an agent trust from this owner?"])
   ((equal? context "macro")
    ["What expansion or hygiene boundary does this macro enforce?"
     "Which runtime-source witness should be checked before editing the transformer?"
     "What generated shape or phase assumption would break downstream policy?"])
   ((equal? context "poo")
    ["What object, generic, method, or protocol contract is being implemented?"
     "Which receiver, specializer, slot, or protocol evidence constrains the edit?"
     "What runtime witness proves this is not a loose alist/hash object encoding?"])
   ((equal? context "higher-order")
    ["What data-flow transform does this expression-level combinator encode?"
     "Which arity/formal evidence makes map/filter/fold/cut/compose appropriate?"
     "What invariant would be hidden if this became a hand-written loop?"])
   ((equal? context "control-flow")
    ["What state, IO, generator, branch, or continuation driver requires explicit control flow?"
     "Which binding and body-shape facts bound the loop or match nesting?"
     "What exit or fallback condition should repairs preserve?"])
   ((equal? context "long-definition")
    ["What large-owner responsibility keeps this definition cohesive?"
     "Which branch, risk, or optimization boundary should repairs preserve?"
     "Which parser facts should guide a later split or simplification?"])
   (else
    ["What stable responsibility does this definition own?"
     "Which invariant or boundary is not obvious from the code mechanics?"
     "What parser fact should an agent use before rewriting this owner?"])))

;; Selector <- Definition
(def (definition-source-selector definition)
  (fact-source-selector (definition-path definition)
                        (definition-start definition)
                        (definition-end definition)))

;; Selector <- Path SourceLine SourceLine
(def (fact-source-selector path start end)
  (string-append path ":" (number->string start) "-" (number->string end)))

;;; Invariant:
;;; - module-leading-comments owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List CommentLine) <- (List SourceLine)
(def (module-leading-comments lines)
  (let ((rest lines)
        (line-number 1)
        (out '())
        (done? #f))
    (while (and (pair? rest) (not done?))
      (let ((line (car rest))
            (more (cdr rest)))
        (cond
         ((and (= line-number 1) (mode-comment-line? line))
          (set! rest more)
          (set! line-number (fx1+ line-number)))
         ((engineering-comment-line? line)
          (set! rest more)
          (set! line-number (fx1+ line-number))
          (set! out (cons (comment-body line) out)))
         ((blank-string? line)
          (if (null? out)
            (begin
              (set! rest more)
              (set! line-number (fx1+ line-number)))
            (set! done? #t)))
         (else
          (set! done? #t)))))
    (reverse out)))

;;; Invariant:
;;; - leading-comment-lines owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List CommentLine) <- (List SourceLine) SourceLineNumber
(def (leading-comment-lines lines start-line)
  (let ((line-number (fx1- start-line))
        (out '())
        (done? #f))
    (while (and (not done?) (fx>= line-number 1))
      (let (line (line-at* lines (fx1- line-number)))
        (if (comment-line? line)
          (begin
            (set! out (cons (comment-body line) out))
            (set! line-number (fx1- line-number)))
          (set! done? #t))))
    out))

;; String <- Definition (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact)
(def (definition-comment-context definition macros poo-forms higher-order-forms control-flow-forms)
  (let ((name (definition-name definition))
        (kind (definition-kind definition)))
    (cond
     ((definition-name-in-macros? name macros) "macro")
     ((or (member kind '("defclass" "defgeneric" "defmethod" "defprotocol"))
          (definition-name-in-poo-forms? name poo-forms))
      "poo")
     ((definition-name-in-higher-order-forms? name higher-order-forms)
      "higher-order")
     ((definition-name-in-control-flow-forms? name control-flow-forms)
      "control-flow")
     ((>= (definition-line-span definition) 24) "long-definition")
     (else "definition"))))

;; Boolean <- Definition String
(def (definition-comment-required? definition context)
  (or (list-member? (definition-kind definition)
                    '("defrule" "defsyntax" "defclass" "defgeneric" "defmethod" "defprotocol"))
      (list-member? context
                    '("macro" "poo" "higher-order" "control-flow" "long-definition"))))

;; CommentSummary <- (List CommentLine) Boolean String
(def (comment-quality-summary comments required context)
  (let* ((kind (comment-kind comments))
         (quality (comment-quality kind required))
         (reasons (comment-quality-reasons kind quality required context)))
    (vector kind quality reasons)))

;;; Boundary:
;;; - comment-kind composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- (List CommentLine)
(def (comment-kind comments)
  (cond
   ((null? comments) "missing")
   ((compressed-engineering-comments? comments) "compressed-engineering")
   ((ormap engineering-boundary-comment? comments) "boundary")
   ((ormap engineering-invariant-comment? comments) "invariant")
   ((ormap engineering-optimization-comment? comments) "optimization")
   ((ormap engineering-risk-comment? comments) "risk")
   ((ormap engineering-intent-comment? comments) "intent")
   ((ormap typed-contract-comment? comments) "contract-only")
   (else "weak")))

;; String <- String Boolean
(def (comment-quality kind required)
  (cond
   ((equal? kind "missing") "absent")
   ((equal? kind "contract-only") "weak")
   ((equal? kind "compressed-engineering") "weak")
   ((equal? kind "weak") "weak")
   ((and required (member kind '("boundary" "invariant" "optimization" "risk")))
    "engineering-grade")
   ((equal? kind "intent") "useful")
   (else "useful")))

;; (List Reason) <- String String Boolean String
(def (comment-quality-reasons kind quality required context)
  (cond
   ((equal? quality "absent")
    ["missing-engineering-comment"])
   ((equal? kind "contract-only")
    ["contract-only-is-not-engineering-comment"])
   ((equal? kind "compressed-engineering")
    ["compressed-engineering-comment-needs-adjacent-lines"])
   ((and required (equal? quality "useful"))
    [(string-append "missing-" context "-boundary-comment")])
   ((equal? quality "weak")
    ["weak-engineering-comment"])
   (else [])))

;;; Boundary:
;;; - Typed contract detection owns algebraic shape only.
;;; - Engineering-rationale classification stays separate from type signatures.
;;; Invariant:
;;; - A contract comment cannot satisfy key-owner rationale by itself.
;; Boolean <- CommentLine
(def (typed-contract-comment? comment)
  (or (string-contains comment "<-")
      (string-prefix? ":" (trim-ascii-space comment))))

;;; Boundary:
;;; - Compressed engineering comments hide separate rationale clauses in one line.
;;; - Keep separate rationale clauses on adjacent lines when splitting improves evidence confidence.
;; Boolean <- (List CommentLine)
(def (compressed-engineering-comments? comments)
  (ormap compressed-engineering-comment? comments))

;;; Boundary:
;;; - A semicolon inside the comment body usually means two rationale clauses were squeezed together.
;;; - Agents should split those clauses rather than forcing every rationale into one line.
;; Boolean <- CommentLine
(def (compressed-engineering-comment? comment)
  (and (engineering-comment-body? comment)
       (string-contains comment ";")))

;; Boolean <- CommentLine
(def (engineering-intent-comment? comment)
  (and (engineering-comment-body? comment)
       (or (comment-contains-any? comment '("intent" "purpose" "why" "because" "agent" "parser" "semantic" "source"))
           (>= (string-length (trim-ascii-space comment)) 36))))

;; Boolean <- CommentLine
(def (engineering-boundary-comment? comment)
  (comment-contains-any? comment '("boundary" "facade" "runtime" "provider" "parser-owned" "source-class" "scope" "contract-visible")))

;; Boolean <- CommentLine
(def (engineering-invariant-comment? comment)
  (comment-contains-any? comment '("invariant" "preserve" "must" "never" "stable" "deterministic")))

;; Boolean <- CommentLine
(def (engineering-optimization-comment? comment)
  (comment-contains-any? comment '("optimization" "fast path" "common case" "specialized" "avoid allocation" "performance")))

;; Boolean <- CommentLine
(def (engineering-risk-comment? comment)
  (comment-contains-any? comment '("risk" "unsafe" "fallback" "avoid" "denied" "drift" "ambiguous")))

;; Boolean <- CommentLine
(def (engineering-comment-body? comment)
  (and (string? comment)
       (not (blank-string? comment))
       (not (typed-contract-comment? comment))))

;;; Boundary:
;;; - comment-contains-any? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String (List String)
(def (comment-contains-any? comment needles)
  (and (string? comment)
       (let (downcased (string-downcase comment))
         (ormap (lambda (needle)
                  (string-contains downcased needle))
                needles))))

;;; Boundary:
;;; - definition-name-in-macros? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String (List MacroFact)
(def (definition-name-in-macros? name macros)
  (ormap (lambda (fact)
           (equal? (macro-fact-name fact) name))
         macros))

;;; Boundary:
;;; - definition-name-in-poo-forms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String (List PooFormFact)
(def (definition-name-in-poo-forms? name poo-forms)
  (ormap (lambda (fact)
           (equal? (poo-form-fact-name fact) name))
         poo-forms))

;;; Boundary:
;;; - definition-name-in-higher-order-forms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String (List HigherOrderFact)
(def (definition-name-in-higher-order-forms? name higher-order-forms)
  (ormap (lambda (fact)
           (equal? (higher-order-fact-caller fact) name))
         higher-order-forms))

;;; Boundary:
;;; - definition-name-in-control-flow-forms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String (List ControlFlowFact)
(def (definition-name-in-control-flow-forms? name control-flow-forms)
  (ormap (lambda (fact)
           (equal? (control-flow-fact-caller fact) name))
         control-flow-forms))

;; Boolean <- SourceLine
(def (comment-line? line)
  (and (string? line)
       (let (trimmed (trim-ascii-space line))
         (and (string-prefix? ";;" trimmed)
              (not (mode-comment-line? trimmed))))))

;; Boolean <- SourceLine
(def (engineering-comment-line? line)
  (and (string? line)
       (let (trimmed (trim-ascii-space line))
         (and (string-prefix? ";;;" trimmed)
              (not (mode-comment-line? trimmed))))))

;; Boolean <- SourceLine
(def (mode-comment-line? line)
  (and (string? line)
       (string-prefix? ";;; -*-" (trim-ascii-space line))))

;; CommentLine <- SourceLine
(def (comment-body line)
  (trim-ascii-space (drop-leading-semicolons (trim-ascii-space line))))

;;; Gerbil-utils contains high-codepoint prose in comments; SRFI-13 trim can throw on those bytes in this runtime path.
;;; Keep parser-owned comment facts robust by trimming only ASCII whitespace around the line.
;; String <- String
(def (trim-ascii-space text)
  (if (string? text)
    (let* ((length (string-length text))
           (start (first-non-ascii-space text length))
           (end (last-non-ascii-space text start length)))
      (substring text start end))
    ""))

;;; Boundary:
;;; - first-non-ascii-space keeps SRFI-13 character-set conversion out of the trim path.
;;; - Indexed character pairs expose the first non-ASCII-space offset without a loop.
;; Integer <- SourceLine SourceLength
(def (first-non-ascii-space text length)
  (let (hit (find (lambda (entry)
                    (not (ascii-space? (car entry))))
                  (map-indexed cons (string->list text))))
    (if hit (fx1- (cdr hit)) length)))

;;; Boundary:
;;; - last-non-ascii-space owns the right trim scan with the caller-provided lower bound.
;;; - Preserve high-codepoint comment bodies and never scan before the left trim boundary.
;; Integer <- SourceLine TrimStart SourceLength
(def (last-non-ascii-space text start length)
  (let (hit (find (lambda (entry)
                    (let (index (fx1- (cdr entry)))
                      (and (fx>= index start)
                           (not (ascii-space? (car entry))))))
                  (reverse (map-indexed cons (string->list text)))))
    (if hit (cdr hit) start)))

;; Boolean <- Character
(def (ascii-space? ch)
  (or (char=? ch #\space)
      (char=? ch #\tab)
      (char=? ch #\newline)
      (char=? ch #\return)))

;;; Boundary:
;;; - Comment markers are stripped by finding the first non-semicolon offset.
;;; - Keep the body substring unchanged after that offset for parser evidence.
;; SourceLine <- SourceLine
(def (drop-leading-semicolons text)
  (let (hit (find (lambda (entry)
                    (not (char=? (car entry) #\;)))
                  (map-indexed cons (string->list text))))
    (substring text
               (if hit (fx1- (cdr hit)) (string-length text))
               (string-length text))))

;; Integer <- Definition
(def (definition-line-span definition)
  (fx1+ (- (definition-end definition)
           (definition-start definition))))

;;; Boundary:
;;; - line-at* is zero-based and total over malformed indices.
;;; - Guard before list-ref so parser facts never raise on drifted line spans.
;; SourceLine <- (List SourceLine) Integer
(def (line-at* lines index)
  (and (>= index 0)
       (< index (length lines))
       (list-ref lines index)))

;; Boolean <- String
(def (blank-string? value)
  (or (not (string? value))
      (= (string-length (trim-ascii-space value)) 0)))

;; Boolean <- Item (List Item)
(def (list-member? item values)
  (if (member item values) #t #f))

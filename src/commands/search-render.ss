;;; -*- Gerbil -*-
;;; Compact search line render helpers for agent-facing source evidence.

(import :support/list)

(export emit-selector-resolver-line
        emit-source-example-line
        emit-source-comment-line
        emit-structural-syntax-fact-lines
        detail-list
        join-or-dash)

(def (emit-selector-resolver-line resolver)
  (displayln "|selectorResolver scheme=" (hash-get resolver 'scheme)
             " owner=" (hash-get resolver 'owner)
             " stateNamespace=" (hash-get resolver 'stateNamespace)
             " versionKey=" (hash-get resolver 'versionKey)
             " selectorFormat=" (hash-get resolver 'selectorFormat)
             " output=" (hash-get resolver 'output)
             " indexOwner=" (hash-get resolver 'indexOwner)))

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

(def (emit-source-comment-line comment)
  (displayln "|sourceComment id=" (hash-get comment 'id)
             " selector=" (hash-get comment 'selector)
             " extractor=" (hash-get comment 'extractor)
             " summary=" (hash-get comment 'summary)
             " fallback=" (hash-get comment 'fallback)))

(def (emit-structural-syntax-fact-lines facts)
  (for-each emit-syntax-fact-line
            (take* (ranked-syntax-facts facts) 16)))

(def (emit-syntax-fact-line fact)
  (let* ((fields (hash-get fact 'fields))
         (location (hash-get fact 'location)))
    (displayln "|syntaxFact kind=" (hash-get fact 'kind)
               " languageKind=" (hash-get fact 'languageKind)
               " name=" (hash-get fact 'name)
               " owner=" (hash-get fact 'ownerPath)
               " range=" (hash-get location 'lineRange)
               " role=" (field-string fields 'role)
               " generic=" (field-string fields 'generic)
               " receiver=" (field-string fields 'receiver)
               " receiverType=" (field-string fields 'receiverType)
               " supers=" (field-list-string fields 'supers)
               " slots=" (field-list-string fields 'slots)
               " options=" (field-list-string fields 'options))))

(def (ranked-syntax-facts facts)
  (dedupe-syntax-facts
   (append (filter poo-syntax-fact? facts)
           (filter macro-or-import-syntax-fact? facts)
           facts)))

(def (poo-syntax-fact? fact)
  (let (fields (hash-get fact 'fields))
    (and fields
         (member (field-string fields 'role)
                 '("class" "generic" "method")))))

(def (macro-or-import-syntax-fact? fact)
  (member (hash-get fact 'kind) '("macro" "import")))

(def (dedupe-syntax-facts facts)
  (let lp ((rest facts) (seen '()) (out '()))
    (match rest
      ([fact . more]
       (let (id (hash-get fact 'id))
         (if (member id seen)
           (lp more seen out)
           (lp more (cons id seen) (cons fact out)))))
      (else (reverse out)))))

(def (field-string fields key)
  (if (and fields (hash-key? fields key))
    (dash-empty (hash-get fields key))
    "-"))

(def (field-list-string fields key)
  (if (and fields (hash-key? fields key))
    (let (value (hash-get fields key))
      (cond
       ((list? value) (join-or-dash value))
       ((string? value) (dash-empty value))
       (else "-")))
    "-"))

(def (dash-empty value)
  (cond
   ((not value) "-")
   ((and (string? value) (fx= (string-length value) 0)) "-")
   (else value)))

(def (detail-list details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))

(def (join-or-dash values)
  (if (null? values)
    "-"
    (join values ",")))

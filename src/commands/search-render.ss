;;; -*- Gerbil -*-
;;; Compact search line render helpers for agent-facing source evidence.

(import :support/list)

(export emit-selector-resolver-line
        emit-source-example-line
        emit-source-comment-line
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

(def (detail-list details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))

(def (join-or-dash values)
  (if (null? values)
    "-"
    (join values ",")))

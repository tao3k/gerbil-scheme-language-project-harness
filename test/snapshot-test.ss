;;; -*- Gerbil -*-
(import :extensions/facade
        :parser/facade
        :protocol/json
        :snapshot/facade
        :std/test)
(export snapshot-test)

(def snapshot-test
  (test-suite "gerbil scheme harness snapshots"
    (test-case "provider extension snapshot uses schema field names"
      (let (fact (make-extension-fact "poo"
                                      "gerbil.pkg"
                                      "required"
                                      "gxpkg"
                                      "sample/app"
                                      ["git.cons.io/mighty-gerbils/gerbil-poo"]
                                      ["object-system"
                                       "metaobject-protocol"
                                       "protocols"]))
        (check (extension-fact-snapshot fact)
               => '(providerExtension
                    (name "poo")
                    (activation "gerbil.pkg")
                    (dependencyMode "required")
                    (packageManager "gxpkg")
                    (package "sample/app")
                    (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
                    (capabilities ("object-system" "metaobject-protocol" "protocols"))))))
    (test-case "check report snapshot uses stable unit interface"
      (check (check-report-snapshot #f '())
             => '(checkReport
                  (languageId "gerbil-scheme")
                  (providerId "gerbil-scheme-harness")
                  (status "pass")
                  (findings ()))))
    (test-case "search prime json exposes required schema envelope"
      (let* ((index (collect-project "."))
             (packet (search-prime-packet-json index))
             (header (hash-get packet 'header)))
        (check (hash-get packet 'schemaId)
               => "agent.semantic-protocols.semantic-search-packet")
        (check (hash-get packet 'schemaVersion) => "1")
        (check (hash-get packet 'protocolId)
               => "agent.semantic-protocols.semantic-language")
        (check (hash-get packet 'protocolVersion) => "1")
        (check (hash-get packet 'languageId) => "gerbil-scheme")
        (check (hash-get packet 'providerId) => "gerbil-scheme-harness")
        (check (hash-get packet 'binary) => "gerbil-scheme-harness")
        (check (hash-get packet 'namespace)
               => "agent.semantic-protocols.gerbil-scheme")
        (check (hash-get packet 'method) => "search/prime")
        (check (hash-get packet 'projectRoot) => (project-index-root index))
        (check (hash-get packet 'view) => "prime")
        (check (hash-get packet 'renderMode) => "facts")
        (check (hash-get header 'kind) => "search-prime")
        (check (> (length (hash-get packet 'nodes)) 0) => #t)
        (check (> (length (hash-get packet 'owners)) 0) => #t)
        (check (> (length (hash-get packet 'hits)) 0) => #t)
        (check (hash-get packet 'findings) => '())
        (check (length (hash-get packet 'nextActions)) => 1)
        (check (length (hash-get packet 'notes)) => 1)))
    (test-case "search prime json carries semantic fact graph"
      (let* ((index (collect-project "."))
             (packet (search-prime-packet-json index)))
        (check (packet-has-node-kind? packet "package") => #t)
        (check (packet-has-node-kind? packet "owner") => #t)
        (check (packet-has-node-kind? packet "extension") => #t)
        (check (packet-has-edge-kind? packet "owns") => #t)
        (check (packet-has-edge-kind? packet "activates") => #t)
        (check (packet-has-note-kind? packet "parser") => #t)))))

(def (packet-has-node-kind? packet kind)
  (ormap (lambda (node)
           (equal? (hash-get node 'kind) kind))
         (hash-get packet 'nodes)))

(def (packet-has-edge-kind? packet kind)
  (ormap (lambda (edge)
           (equal? (hash-get edge 'kind) kind))
         (hash-get packet 'edges)))

(def (packet-has-note-kind? packet kind)
  (ormap (lambda (note)
           (equal? (hash-get note 'kind) kind))
         (hash-get packet 'notes)))

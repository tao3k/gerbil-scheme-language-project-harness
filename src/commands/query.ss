;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Query command adapter.

(import :extensions/facade
        :parser/facade
        :parser/query
        :protocol/json
        (only-in :std/sugar unless)
        :support/args
        :support/io
        :support/list)

(export query-main)
;; query-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `query-main args` dispatches selector reads and query requests for the
;;       agent-facing source query command.
;;
;;       # Examples
;;
;;       ```scheme
;;       (query-main '("--selector" "src/core.ss:1-1" "--workspace" "."))
;;       ;; => 0
;;       ```
;;     %
(def (query-main args)
  (let* ((workspace (or (option "--workspace" args) (project-root args)))
         (json? (flag? "--json" args))
         (code? (flag? "--code" args))
         (names-only? (flag? "--names-only" args))
         (selector (option "--selector" args))
         (from-hook (option "--from-hook" args)))
    (cond
     ((and from-hook (equal? from-hook "direct-source-read") (not selector))
      (error "direct-source-read requires --selector"))
     (selector
      (let (code (read-selector workspace selector))
        (if json?
          (write-json-line (hash (selector selector) (code code)))
          (display code)))
      0)
     (else
      (let* ((positionals (positional-args (drop-project-root args)))
             (owner (and (pair? positionals) (car positionals)))
             (terms (options "--term" args)))
        (if (and (not owner) (poo-registered-extension-query? terms))
          (begin
            (emit-registered-poo-query-route terms json?)
            0)
        (if (and (not owner) names-only? (pair? terms))
          (begin
            (displayln "query --names-only requires an owner selector; workspace term discovery is `search fzf '<term>' owner --workspace <workspace-root> --view seeds`")
            2)
          (begin
            (unless owner (error "query requires an owner path"))
            (if (not (owner-path-exists? workspace owner))
              (begin
                (displayln "query owner path does not exist under --workspace: "
                           owner
                           " workspace="
                           workspace)
                2)
              (let* ((index (collect-project workspace))
                     (file (find-owner index owner)))
                (unless file (error "owner not found" owner))
                (let (matches (matching-definitions (source-file-definitions file) terms))
                  (cond
                   (json?
                    (write-json-line (hash (owner (source-file-path file))
                                           (matches (map definition-json matches)))))
                   (code?
                    (for-each (lambda (defn)
                                (display (read-definition-code workspace defn)))
                              matches))
                   (names-only?
                    (for-each (lambda (defn) (displayln (definition-name defn))) matches))
                   (else
                    (emit-owner-items file matches))))
                0))))))))))
;; : (-> ProjectIndex String Boolean )
(def (owner-path-exists? workspace owner)
  (file-exists? (path-expand owner workspace)))
;; emit-owner-items
;;   : (-> SourceFile (List Definition) Unit)
;;   | doc m%
;;       `emit-owner-items file matches` prints compact owner item rows for the
;;       matched definitions in a source file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-owner-items file matches)
;;       ;; => (void)
;;       ```
;;     %
(def (emit-owner-items file matches)
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (length matches))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   matches))
;;; Boundary:
;;; - emit-registered-poo-query-route keeps ownerless query semantically precise.
;;; - gerbil-poo:// is registered knowledge, not a workspace activation fallback.
;; : (-> Terms Boolean Unit )
(def (emit-registered-poo-query-route terms json?)
  (let* ((query (join terms " "))
         (pattern-next (string-append "search pattern gerbil-poo "
                                      (registered-poo-query-focus terms)))
         (extension-command
          (string-append "asp gerbil-scheme search extension " query
                         " --view seeds"))
         (pattern-command
          (string-append "asp gerbil-scheme " pattern-next
                         " --view seeds"))
         (source-ref (poo-source-ref #f)))
    (if json?
      (write-json-line
       (hash (query query)
             (route "registered-extension")
             (registeredKnowledge "gerbil-poo://")
             (notProjectActivation #t)
             (extensionCommand extension-command)
             (patternCommand pattern-command)
             (sourceRef source-ref)
             (sourceLookup (query-source-lookup-json source-ref))
             (next pattern-next)))
      (begin
        (displayln "[gerbil-query-route] query=" query
                   " route=registered-extension"
                   " evidenceGrade=fact")
        (displayln "|registeredKnowledge uri=gerbil-poo://"
                   " notProjectActivation=true"
                   " selectorUse=logical-source-anchor")
        (displayln "|agentAction action=use-search-pattern"
                   " first=\"" extension-command "\""
                   " second=\"" pattern-command "\""
                   " missingLocalAction=install-package-before-repository-fallback"
                   " fallback=repository-source-after-install-check")
        (emit-query-source-lookup-line source-ref)
        (displayln "next=" pattern-next)))))
;;; Boundary:
;;; - registered-poo-query-focus preserves user intent after the extension token.
;;; - Default to usage so bare gerbil-poo queries still route to executable patterns.
;; : (-> Terms String )
(def (registered-poo-query-focus terms)
  (poo-registered-extension-focus terms))
;;; Boundary:
;;; - query-source-lookup-json is the machine packet mirror of the text line.
;;; - Keep the lookup order and index owner explicit for non-interactive agents.
;; : (-> SourceRef Json )
(def (query-source-lookup-json source-ref)
  (let* ((local-source (hash-get source-ref 'localSource))
         (repository-source (hash-get source-ref 'repositorySource))
         (index-hint (hash-get source-ref 'indexHint)))
    (hash (order "local-source-before-git")
          (missingLocalAction (hash-get index-hint 'missingLocalAction))
          (fallbackPolicy (hash-get index-hint 'fallbackPolicy))
          (localRootHint (hash-get local-source 'rootHint))
          (localPackage (hash-get local-source 'package))
          (localStatus (hash-get local-source 'status))
          (localMissingAction (hash-get local-source 'missingAction))
          (installHint (hash-get local-source 'installHint))
          (repository (hash-get repository-source 'repository))
          (repositoryUrl (hash-get repository-source 'url))
          (indexOwner (hash-get index-hint 'owner))
          (indexBackend (hash-get index-hint 'backend))
          (indexPackageManager (hash-get index-hint 'packageManager)))))
;;; Boundary:
;;; - emit-query-source-lookup-line mirrors search output for query routes.
;;; - Keep local-source-before-git order explicit so agents do not treat this as fallback.
;; : (-> SourceRef Unit )
(def (emit-query-source-lookup-line source-ref)
  (let* ((local-source (hash-get source-ref 'localSource))
         (repository-source (hash-get source-ref 'repositorySource))
         (index-hint (hash-get source-ref 'indexHint)))
    (displayln "|sourceLookup order=local-source-before-git"
               " missingLocalAction=" (hash-get index-hint 'missingLocalAction)
               " fallbackPolicy=" (hash-get index-hint 'fallbackPolicy)
               " localRootHint=" (hash-get local-source 'rootHint)
               " localPackage=" (hash-get local-source 'package)
               " localStatus=" (hash-get local-source 'status)
               " localMissingAction=" (hash-get local-source 'missingAction)
               " installHint=\"" (hash-get local-source 'installHint) "\""
               " repository=" (hash-get repository-source 'repository)
               " repositoryUrl=" (hash-get repository-source 'url)
               " indexOwner=" (hash-get index-hint 'owner)
               " indexBackend=" (hash-get index-hint 'backend)
               " indexPackageManager=" (hash-get index-hint 'packageManager))))

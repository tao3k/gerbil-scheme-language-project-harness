;;; -*- Gerbil -*-
;;; Query command adapter.

(import :parser/facade
        :parser/query
        :protocol/json
        :std/sugar
        :support/args
        :support/io)

(export query-main)

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
        (if (and (not owner) names-only? (pair? terms))
          (begin
            (displayln "query --names-only requires an owner selector; workspace term discovery is `search fzf '<term>' owner --view seeds --workspace <workspace-root>`")
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
                0)))))))))

(def (owner-path-exists? workspace owner)
  (file-exists? (path-expand owner workspace)))

(def (emit-owner-items file matches)
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (length matches))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   matches))

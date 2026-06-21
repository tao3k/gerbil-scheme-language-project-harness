;;; -*- Gerbil -*-
;;; Owner-items fast-path unit checks.
;;; These tests guard launcher shape and parser-owned owner item limits.

(import :gerbil/gambit
        :commands/guide-sections
        :commands/search-owner-items
        :parser/owner-items
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-contains string-index string-prefix?)
        :std/test)

(export check-owner-items-limit-budget
        check-owner-items-gerbil-package-facts
        check-owner-items-fast-entrypoint-stays-light
        check-owner-items-omits-empty-role-field
        check-guide-sections-static-data-loads
        check-search-guide-fast-entrypoint-stays-light)

;; FixturePath
(def +owner-items-fixture+ "t/fixtures/parser/complex-syntax.ss")

;; : (-> () Unit )
(def (check-owner-items-limit-budget)
  (let* ((file (parse-owner-items-source-file "."
                                              (path-expand +owner-items-fixture+ ".")))
         (all (matching-owner-syntax-facts file '()))
         (limited (matching-owner-syntax-facts file '() 3)))
    (check (> (length all) 3) => #t)
    (check (length limited) => 3)
    (check (owner-item-query-terms "projection|chain receipt")
           => ["projection" "chain" "receipt"])))

;;; Regression: gerbil.pkg is a package owner, not an empty config blob.
;;; Owner-items should expose package metadata through parser-owned facts so
;;; agents can query dependencies and policy without raw file reads.
;; : (-> () Unit )
(def (check-owner-items-gerbil-package-facts)
  (let* ((file (parse-owner-items-source-file "." "gerbil.pkg"))
         (facts (matching-owner-syntax-facts file ["gerbil.pkg"] 10 "."))
         (package-fact
          (find (lambda (fact)
                  (equal? (hash-get fact 'kind) "package"))
                facts)))
    (check (not (not package-fact)) => #t)
    (check (hash-get package-fact 'name)
           => "gerbil-scheme-language-project-harness")
    (check (not (not (member "git.cons.io/mighty-gerbils/gerbil-poo"
                              (hash-get package-fact 'queryKeys))))
           => #t)
    (check (not (not (member "source-scope"
                              (hash-get package-fact 'queryKeys))))
           => #t)))

;; : (-> () Unit )
(def (check-owner-items-fast-entrypoint-stays-light)
  (let (source
        (call-with-input-file
            "src/search-fast/gerbil-scheme-search-owner-items.ss"
          read-all-as-string))
    (check (source-contains? source ":commands/search-owner-items") => #t)
    (check (source-contains? source ":parser/owner-items") => #f)
    (check (source-contains? source ":parser/facade") => #f)
    (check (source-contains? source ":commands/search\n") => #f)
    (check (source-contains? source ":commands/search ") => #f)
    (check (source-contains? source ":commands/search)") => #f)
    (check (source-contains? source ":cli") => #f)))

;; : (-> () Unit )
(def (check-owner-items-omits-empty-role-field)
  (let* ((file (parse-owner-items-source-file
                (path-expand +owner-items-fixture+)))
         (facts (matching-owner-syntax-facts file ["call"] 4))
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (emit-owner-items file [] facts 4))))))
    (check (> (length facts) 0) => #t)
    (check (source-contains? output " languageKind=call") => #t)
    (check (source-contains? output " role=") => #f)))

;; : (-> () Unit )
(def (check-search-guide-fast-entrypoint-stays-light)
  (let (source
        (call-with-input-file
            "src/search-fast/gerbil-scheme-search-guide.ss"
          read-all-as-string))
    (check (source-contains? source ":commands/guide-sections") => #t)
    (check (source-contains? source ":commands/search\n") => #f)
    (check (source-contains? source ":commands/search ") => #f)
    (check (source-contains? source ":commands/search)") => #f)
    (check (source-contains? source ":cli") => #f)))

;; : (-> () Unit )
(def (check-guide-sections-static-data-loads)
  (let (lines (guide-section-lines-for ["--poo"]))
    (check (car lines) => "gerbil-scheme-harness guide")
    (check (not (not (member "|cmd pattern-poo=gerbil-scheme-harness search pattern poo [term ...] --view seeds"
                              lines)))
           => #t)
    (check (not (not (member "|policy poo-structural-facts=search structural --owner <path> --json exposes parser-owned POO forms as custom/generic/method owner facts with role,supers,slots,options,specializers,specializerTypes,dispatchArity; query owner facts before editing POO object/type/method forms"
                              lines)))
           => #t)))

;; : (-> SourceText Needle Boolean )
(def (source-contains? source needle)
  (and (string-contains source needle) #t))

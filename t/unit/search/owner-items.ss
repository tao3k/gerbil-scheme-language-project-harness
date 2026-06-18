;;; -*- Gerbil -*-
;;; Owner-items fast-path unit checks.
;;; These tests guard launcher shape and parser-owned owner item limits.

(import :gerbil/gambit
        :clan/base
        :commands/guide-sections
        :commands/search-owner-items
        :parser/owner-items
        (only-in :std/misc/ports read-all-as-string)
        :std/misc/process
        (only-in :std/srfi/13 string-contains string-index string-prefix?)
        :std/test)

(include "../../../build-support/provider-cli.ss")

(export check-owner-items-limit-budget
        check-provider-launcher-native-fast-route
        check-owner-items-fast-entrypoint-stays-light
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

;; : (-> () Unit )
(def (check-provider-launcher-native-fast-route)
  (let* ((config
          (provider-cli-config
           "/tmp/asp/gerbil-scheme-harness"
           "/tmp/asp/gerbil-harness"))
         (dispatcher-source (native-dispatcher-source-text config))
         (provider-source
          (call-with-input-file
              "build-support/provider-cli.ss"
            read-all-as-string)))
    (check (assoc 'fast-owner-items config)
           => '(fast-owner-items . "/tmp/asp/gerbil-scheme-search-owner-items"))
        (check (assoc 'search-runtime config)
           => '(search-runtime . "/tmp/asp/gerbil-harness/src/search-fast/gerbil-scheme-search.ss"))
    (check (source-contains? dispatcher-source "owner_items_native_main") => #t)
    (check (source-contains? dispatcher-source "return owner_items_native_main(argc, argv);") => #t)
    (check (source-contains? dispatcher-source "exec_forward(fast_owner_items") => #f)
    (check (source-contains? dispatcher-source "run-native-or-script!") => #f)
    (check (source-contains? dispatcher-source "owner_items_script") => #f)
    (check (source-contains? dispatcher-source "missing required %s artifact") => #t)
    (check (source-contains? dispatcher-source "run `gxi build.ss compile`") => #t)
    (check (source-contains? dispatcher-source "missing native") => #f)
    (check (source-contains? dispatcher-source "#!/usr/bin/env sh") => #f)
    (check (source-contains? provider-source "write-gerbil-script-launcher") => #f)
    (check (source-contains? provider-source "#!/usr/bin/env gxi") => #f)))

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

;;; -*- Gerbil -*-
;;; Gerbil scheme harness repeated alist lookup policy tests.

(import :gerbil/gambit
        :std/test
        :parser/facade
        :policy/facade
        :policy/fixtures
        :types/facade)

(export agent-alist-access-policy-test)

;; PolicyTest
(def agent-alist-access-policy-test
  (test-suite "gerbil scheme harness alist access policy"
    (test-case "agent policy rejects repeated inline assq cdr lookups"
      (let* ((root ".run/policy-alist-inline")
             (source-dir (string-append root "/src/profile")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/profile)\n")
        (write-text
         (string-append source-dir "/bad.ss")
         ";;; -*- Gerbil -*-\n(def (profile-name profile)\n  (cdr (assq 'name profile)))\n(def (profile-owner profile)\n  (cdr (assq 'owner profile)))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-R022" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/profile/bad.ss")
          (check (hash-get details 'kind) => "repeated-inline-alist-lookup")
          (check (hash-get details 'lookupCount) => 2)
          (check (if (member "alist:name" (hash-get details 'fieldKeys)) #t #f)
                 => #t)
          (check (if (member "alist:owner" (hash-get details 'fieldKeys)) #t #f)
                 => #t)
          (check (if (member "profile-name" (hash-get details 'callers)) #t #f)
                 => #t)
          (check (if (member "profile-owner" (hash-get details 'callers)) #t #f)
                 => #t))))
    (test-case "agent policy accepts one named alist bridge"
      (let* ((root ".run/policy-alist-helper")
             (source-dir (string-append root "/src/profile")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/profile)\n")
        (write-text
         (string-append source-dir "/good.ss")
         ";;; -*- Gerbil -*-\n(def (profile-ref profile key)\n  (cdr (assq key profile)))\n(def (profile-name profile)\n  (profile-ref profile 'name))\n(def (profile-owner profile)\n  (profile-ref profile 'owner))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-R022" findings)))
          (check matching => []))))))

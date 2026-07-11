;;; -*- Gerbil -*-
;;; CLI development linker integration contracts.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (rename-in :gslph/src/cli-dev-linker (main dev-linker-main)))
(export cli-dev-linker-test)

;; : TestSuite
(def cli-dev-linker-test
  (test-suite "gerbil scheme harness CLI dev linker"
    (test-case "dev binary routes structural selectors through parser query"
      (let (status #f)
        (let (output
              (with-output-to-string
                (lambda ()
                  (set! status
                    (dev-linker-main
                     "query"
                     "--selector"
                     "gerbil-scheme://src/parser/selectors.ss#item/function/selector-from"
                     "--workspace"
                     "."
                     "--code")))))
          (check status => 0)
          (check (and (string-contains
                       output
                       "(def (selector-from")
                      #t)
                 => #t))))))

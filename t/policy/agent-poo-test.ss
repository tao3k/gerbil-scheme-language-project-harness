;;; -*- Gerbil -*-
;;; gerbil scheme harness agent poo policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :commands/check
        :parser/facade
        :policy/facade
        :policy/gxtest
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export agent-poo-policy-test)
;; PolicyTest
(def agent-poo-policy-test
  (test-suite "gerbil scheme harness agent poo policy"
    (test-case "agent policy rejects direct POO writeenv calls"
          (let* ((root ".run/policy-poo-direct-writeenv")
                 (_ (write-poo-direct-writeenv-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R006" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R006")
            (check (type-finding-path finding) => "src/orders/io.ss")
            (check (type-finding-message finding)
                   => "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first")))
    (test-case "agent policy requires runtime-source witness for POO IO overrides"
          (let* ((root ".run/policy-poo-io-runtime-witness")
                 (_ (write-poo-io-override-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R007" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R007")
            (check (type-finding-path finding) => "src/orders/io.ss")
            (check (type-finding-message finding)
                   => "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified")))
    (test-case "agent policy requires POO method generic and class facts"
          (let* ((root ".run/policy-poo-method-shape")
                 (_ (write-poo-method-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R008" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R008")
            (check (type-finding-path finding) => "src/orders/methods.ss")
            (check (type-finding-message finding)
                   => "POO method order-discount is missing parser-owned defgeneric,defclass-or-defprotocol facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")))
    (test-case "agent policy requires macro runtime-source witness"
          (let* ((root ".run/policy-macro-runtime-source")
                 (_ (write-macro-runtime-source-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R011" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/macros/core.ss")
            (check (hash-get (type-finding-details finding) 'next)
                   => "search runtime-source macro sugar module-sugar")))
    (test-case "agent policy accepts macro runtime-source witness policy"
          (let* ((root ".run/policy-macro-runtime-source-allowed")
                 (_ (write-macro-runtime-source-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R011" findings)))
            (check matching => [])))
    (test-case "agent policy requires declared protocol evidence"
          (let* ((root ".run/policy-protocol-evidence")
                 (_ (write-protocol-evidence-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R012" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/protocol.ss")
            (check (hash-get (type-finding-details finding) 'next)
                   => "search pattern poo protocol")))
    (test-case "agent policy accepts declared protocol evidence"
          (let* ((root ".run/policy-protocol-evidence-positive")
                 (_ (write-protocol-evidence-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R012" findings)))
            (check matching => [])))
    (test-case "agent policy catches downstream POO implementation drift"
          (let* ((root ".run/policy-downstream-poo-agent")
                 (_ (write-downstream-poo-agent-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (vague (filter-rule "GERBIL-SCHEME-AGENT-R004" findings))
                 (direct-writeenv (filter-rule "GERBIL-SCHEME-AGENT-R006" findings))
                 (runtime-witness (filter-rule "GERBIL-SCHEME-AGENT-R007" findings))
                 (method-shape (filter-rule "GERBIL-SCHEME-AGENT-R008" findings))
                 (object-model (filter-rule "GERBIL-SCHEME-AGENT-R010" findings)))
            (check (length vague) => 1)
            (check (length direct-writeenv) => 1)
            (check (length runtime-witness) => 1)
            (check (length method-shape) => 1)
            (check (length object-model) => 1)
            (check (type-finding-path (car vague)) => "src/orders/core.ss")
            (check (type-finding-path (car direct-writeenv)) => "src/orders/io.ss")
            (check (type-finding-path (car runtime-witness)) => "src/orders/io.ss")
            (check (type-finding-path (car method-shape)) => "src/orders/io.ss")
            (check (type-finding-path (car object-model)) => "src/orders/core.ss")
            (check (type-finding-selector (car object-model)) => "src/orders/core.ss:4-4")))
    (test-case "agent policy accepts downstream POO pattern-guided implementation"
          (let* ((root ".run/policy-downstream-poo-agent-positive")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index)))
            (check findings => [])))
    (test-case "agent policy warns on broad runtime imports"
          (let* ((root ".run/policy-explicit-precise-import")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/broad.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :std/srfi/13)\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (write-text (string-append owner "/precise.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import (only-in :std/srfi/13 string-prefix?))\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R018" findings))
                   (finding (car matching)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/broad.ss")
              (check (type-finding-selector finding) => "src/orders/broad.ss:3-3"))))
    (test-case "agent policy rejects duplicate facade exports"
          (let* ((root ".run/policy-export-conflict")
                 (_alpha (write-facade-policy-project
                          root "alpha"
                          ";;; -*- Gerbil -*-\n;;; Alpha facade.\n(export value)\n"
                          ";;; -*- Gerbil -*-\n;;; Alpha core.\n(def value 1)\n"))
                 (_beta (write-facade-policy-project
                         root "beta"
                         ";;; -*- Gerbil -*-\n;;; Beta facade.\n(export value)\n"
                         ";;; -*- Gerbil -*-\n;;; Beta core.\n(def value 2)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R003" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-R003")
            (check (type-finding-path finding) => "src/beta/facade.ss")))))

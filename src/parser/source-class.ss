;;; -*- Gerbil -*-
;;; Parser-owned source path classification for agent-facing projections.

(import (only-in :std/srfi/13 string-contains string-prefix?))

(export source-path-class)
;; String <- String
(def (source-path-class path)
  (cond
   ((or (equal? path "gerbil.pkg")
        (equal? path "build.ss"))
    "config")
   ((or (string-prefix? "t/snapshots/" path)
        (string-contains path "/snapshots/"))
    "snapshot-output")
   ((or (string-prefix? "t/fixtures/" path)
        (string-contains path "/fixtures/"))
    "fixture")
   ((or (string-prefix? "t/" path)
        (string-contains path "/t/"))
    "test")
   ((or (string-contains path "/generated/")
        (string-contains path ".generated."))
    "generated")
   ((or (string-prefix? "src/" path)
        (string-prefix? "bin/" path))
    "runtime-source")
   (else "source")))

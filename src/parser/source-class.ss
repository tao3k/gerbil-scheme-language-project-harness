;;; -*- Gerbil -*-
;;; Parser-owned source path classification for agent-facing projections.

(import (only-in :std/srfi/13 string-contains string-prefix? string-suffix?))

(export source-path-class)
;;; Boundary:
;;; - Source classes are parser-owned vocabulary for policy scope guards.
;;; - Build policy consumes package-build and build-support-runtime classes
;;;   instead of repeating path predicates in policy code.
;;; Invariant:
;;; - Specific build/runtime paths are classified before broad source fallbacks.
;; : (-> SourcePath SourceClass )
(def (source-path-class path)
  (cond
   ((equal? path "gerbil.pkg")
    "config")
   ((equal? path "build.ss")
    "package-build")
   ((and (string-prefix? "build-support/" path)
         (string-suffix? ".ss" path))
    "build-support-runtime")
   ((or (string-prefix? "t/snapshots/" path)
        (string-contains path "/snapshots/"))
    "snapshot-output")
   ((or (string-prefix? "t/scenarios/" path)
        (string-contains path "/scenarios/"))
    "policy-scenario")
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

;;; Intent: translate gxtest source metadata into a bounded Gambit runtime
;;; profile, keeping memory-regression enforcement inside the test framework.
(export declare-gxtest-memory-exception
        gxtest-file-memory-max-heap-mib
        gxtest-file-memory-exception?
        gxtest-file-memory-runtime-options)

(import :gerbil/gambit
        (only-in :std/srfi/1 find)
        (only-in ./gxtest-syntax gxtest-file-forms))

;;; This module is the sole translation boundary from test-source metadata to
;;; Gambit runtime arguments.  It keeps resource policy out of product CLI code.
(def +gxtest-memory-exception-declaration+
  'declare-gxtest-memory-exception)

;;; An exceptional memory budget is explicit in test source, so ordinary
;;; gxtest files retain their normal execution mode.
(defrules declare-gxtest-memory-exception ()
  ((_ profile)
   (begin)))

;;; Any exception declaration is source metadata so a malformed bound cannot
;;; silently use the unrestricted in-process test path.
;; : (-> Form Boolean)
(def (gxtest-memory-exception-declaration? form)
  (and (pair? form)
       (eq? (car form) +gxtest-memory-exception-declaration+)
       (pair? (cdr form))))

;; : (-> Form Boolean)
(def (gxtest-memory-exception-form? form)
  (and (gxtest-memory-exception-declaration? form)
       (let (value (cadr form))
         (and (pair? value)
              (eq? (car value) 'quote)
              (pair? (cdr value))))))

;;; Intent: only a recognized declaration reaches this projection, keeping
;;; malformed top-level forms from being interpreted as resource policy.
(def (gxtest-memory-profile-value form)
  (cadr (cadr form)))

;;; A profile has one authoritative =maxHeapMiB= entry; combining duplicate
;;; bounds would make the selected runtime budget ambiguous.
;; : (-> (List (Pair Symbol Integer)) (Maybe Integer))
(def (gxtest-memory-profile-max-heap-mib profile)
  (let loop ((entries profile))
    (cond
     ((null? entries) #f)
     ((not (pair? entries)) #f)
     ((and (pair? (car entries))
           (eq? (caar entries) 'maxHeapMiB))
      (cdar entries))
     (else
     (loop (cdr entries))))))

;;; Invariant: invalid declarations fail before execution; treating them as no
;;; profile would turn a memory regression into an unbounded test run.
;; : (-> Path (Maybe Integer))
(def (gxtest-file-memory-max-heap-mib file)
  (let (form (find gxtest-memory-exception-declaration?
                  (gxtest-file-forms file)))
    (if form
      (if (gxtest-memory-exception-form? form)
        (let (max-heap-mib
              (gxtest-memory-profile-max-heap-mib
               (gxtest-memory-profile-value form)))
          (if (and (integer? max-heap-mib) (> max-heap-mib 0))
            max-heap-mib
            (error "invalid gxtest memory exception" file)))
        (error "invalid gxtest memory exception" file))
      #f)))

;;; Classification is derived from the declaration itself, never from a test
;;; filename, so renamed scenarios retain the same exception contract.
;; : (-> Path Boolean)
(def (gxtest-file-memory-exception? file)
  (number? (gxtest-file-memory-max-heap-mib file)))

;;; The runner consumes an argv fragment so the cap reaches Gambit before test
;;; source loading and cannot be affected by the test body's allocation order.
;; : (-> Path (List String))
(def (gxtest-file-memory-runtime-options file)
  (let (max-heap-mib (gxtest-file-memory-max-heap-mib file))
    (if max-heap-mib
      [(string-append "-:max-heap="
                      (number->string max-heap-mib)
                      "M")]
      [])))

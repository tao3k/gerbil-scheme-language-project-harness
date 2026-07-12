;;; -*- Gerbil -*-
;;; Declarative execution metadata for tests that own shared process resources.

(import :gerbil/gambit
        (only-in :std/srfi/1 find)
        (only-in ./gxtest-syntax gxtest-file-forms))

(export declare-gxtest-serial
        gxtest-file-serial-resource
        gxtest-file-serial?)

;;; This symbol is the source-level protocol tag consumed by discovery. Keeping
;;; it literal lets the parser classify tests without loading their modules.
;; : SerialDeclarationTag
(def +gxtest-serial-declaration+ 'declare-gxtest-serial)

;; declare-gxtest-serial
;;   : (-> SerialResourceReason Syntax)
;;   | doc m%
;;       Declares that a test owns a shared process resource and therefore
;;       belongs to the serial per-file execution lane.
;;
;;       # Examples
;;
;;       ```scheme
;;       (declare-gxtest-serial shared-native-provider)
;;       ;; => no runtime test-body code
;;       ```
;;     %
(defrules declare-gxtest-serial ()
  ((_ reason)
   (begin)))

;; gxtest-serial-declaration?
;;   : (-> TestSourceForm Boolean)
;;   | doc m%
;;       Recognizes one literal serial-lane declaration while rejecting
;;       malformed source metadata before execution planning.
;;
;;       # Examples
;;
;;       ```scheme
;;       (gxtest-serial-declaration?
;;        '(declare-gxtest-serial shared-native-provider))
;;       ;; => #t
;;       ```
;;     %
(def (gxtest-serial-declaration? form)
  (and (pair? form)
       (eq? (car form) +gxtest-serial-declaration+)
       (pair? (cdr form))
       (symbol? (cadr form))))

;; gxtest-file-serial-resource
;;   : (-> TestSourcePath (OrFalse SerialResourceReason))
;;   | doc m%
;;       Returns the parser-owned shared resource identity declared by a test.
;;       Tests with the same identity must run in order, while distinct resource
;;       groups may use separate native execution lanes.
;;
;;       # Examples
;;
;;       ```scheme
;;       (gxtest-file-serial-resource "t/query-test.ss")
;;       ;; => shared-native-provider
;;       ```
;;     %
(def (gxtest-file-serial-resource file)
  (let (declaration
        (find gxtest-serial-declaration?
              (gxtest-file-forms file)))
    (and declaration (cadr declaration))))

;; : (-> TestSourcePath Boolean)
(def (gxtest-file-serial? file)
  (and (gxtest-file-serial-resource file) #t))

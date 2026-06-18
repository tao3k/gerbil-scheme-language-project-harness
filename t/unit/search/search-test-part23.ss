;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records explicit owner-path parsing expectations.
;;; - Keep fixture ownership outside indexed roots.
(import :std/test
        :commands/search
        (only-in :std/srfi/13 string-contains))
(export search-test-part-23)
;; : (-> (List XX) SearchOutput )
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; : (-> String Unit )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> Unit Path )
(def (write-explicit-owner-fixture)
  (let* ((root ".run/search-explicit-owner")
         (path (string-append root "/outside-owner.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (write-text
     path
     ";;; -*- Gerbil -*-\n(def (outside-owner-query value)\n  value)\n(defgeneric (:outside-render self))\n(defclass (<OutsideOwner> Object) (value) transparent: #t)\n(defmethod (:outside-render (self <OutsideOwner>))\n  (.@ self value))\n")
    path))
;; SearchTest
;; TestSuite
(def search-test-part-23
  (test-suite "gerbil scheme harness search part 23"
    (test-case "owner items parse explicit Gerbil file outside indexed roots"
          (let* ((path (write-explicit-owner-fixture))
                 (output
                  (search-output ["owner" path "items"
                                  "--query"
                                  "outside-owner-query|outside-render|OutsideOwner"
                                  "--view"
                                  "seeds"])))
            (check (contains? output "path=.run/search-explicit-owner/outside-owner.ss") => #t)
            (check (contains? output "kind=def name=outside-owner-query") => #t)
            (check (contains? output "kind=generic name=:outside-render") => #t)
            (check (contains? output "kind=class name=<OutsideOwner>") => #t)))))

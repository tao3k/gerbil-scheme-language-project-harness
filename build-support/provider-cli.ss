;;; -*- Gerbil -*-
;;; Provider executable materialization.

;;; Boundary:
;;; - Runtime behavior lives in normal Gerbil script sources.
;;; - This build owner only installs script launchers and config data.

;; Path <- Path String
(def (write-file! path contents)
  (create-directory* (path-directory path))
  (call-with-output-file path
    (cut write-string contents <>))
  path)

;; Path <- Path Datum
(def (write-datum-file! path datum)
  (create-directory* (path-directory path))
  (call-with-output-file path
    (lambda (out)
      (write datum out)
      (newline out)))
  path)

;; Path <- Path
(def (make-executable! path)
  (invoke "chmod" ["+x" path])
  path)

;; String <- Path
(def (build-support-source name)
  (call-with-input-file
      (path-expand name (current-directory))
    read-all-as-string))

;; Path <- Path String Datum
(def (write-gerbil-script-launcher! path runtime-source launch-form)
  (write-file!
   path
   (string-append
    "#!/usr/bin/env gxi\n"
    ";; -*- Gerbil -*-\n"
    runtime-source
    "\n"
    (call-with-output-string [] (cut write launch-form <>))
    "\n"))
  (make-executable! path))

;; Path <- BuildPrefix Path Path
(def (write-gsc-wrapper! build-prefix real-gsc gambit-root)
  (write-gerbil-script-launcher!
   (path-expand "bin/gsc-gerbil-build" build-prefix)
   (build-support-source "build-support/gsc-wrapper-runtime.ss")
   `(def (main . args)
      (gsc-wrapper-main ,real-gsc
                        ,(string-append "-:~~=" gambit-root)
                        args))))

;; Path <- BuildPrefix
(def (write-native-link-wrapper! build-prefix)
  (write-gerbil-script-launcher!
   (path-expand "bin/gerbil-native-link" build-prefix)
   (build-support-source "build-support/native-wrapper-runtime.ss")
   '(def (main tmp final)
      (native-link-main tmp final))))

;; Path <- BuildPrefix
(def (write-native-diagnose-wrapper! build-prefix)
  (write-gerbil-script-launcher!
   (path-expand "bin/gerbil-native-diagnose" build-prefix)
   (build-support-source "build-support/native-wrapper-runtime.ss")
   '(def (main tmp)
      (native-diagnose-main tmp))))

;; Config <- Path Path
(def (provider-cli-config binary harness-root)
  `((harness-root . ,harness-root)
    (fast-extension . ,(path-expand "gerbil-scheme-search-extension"
                                    (path-directory binary)))
    (extension-script . ,(path-expand
                          "src/search-fast/gerbil-scheme-search-extension.ss"
                          harness-root))
    (search-script . ,(path-expand
                       "src/search-fast/gerbil-scheme-search.ss"
                       harness-root))
    (harness-script . ,(path-expand
                        "bin/gerbil-scheme-harness.ss"
                        harness-root))))

;; Path <- Path Path
(def (write-provider-cli-wrapper! binary harness-root)
  (let (config-path (string-append binary ".config"))
    (write-datum-file! config-path (provider-cli-config binary harness-root))
    (write-gerbil-script-launcher!
     binary
     (build-support-source "build-support/provider-cli-runtime.ss")
     `(def (main . args)
        (provider-cli-main ,config-path args)))))

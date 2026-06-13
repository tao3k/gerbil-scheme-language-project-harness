#!/usr/bin/env gxi
;; -*- Gerbil -*-
(import :std/build-script
        :std/misc/process)

(def (build-prefix)
  (getenv "GERBIL_BUILD_PREFIX" (path-expand ".build/gerbil" (current-directory))))

(def (gerbil-bin name)
  (let ((default-bin (path-expand (string-append "bin/" name) (gerbil-home)))
        (sibling-bin (path-expand (string-append "../bin/" name) (gerbil-home))))
    (if (file-exists? default-bin) default-bin sibling-bin)))

(def (write-gsc-wrapper real-gsc gambit-root)
  (let ((wrapper (path-expand "bin/gsc-gerbil-build" (build-prefix))))
    (create-directory* (path-directory wrapper))
    (call-with-output-file wrapper
      (lambda (out)
        (display "#!/bin/sh\nexec " out)
        (write real-gsc out)
        (display " " out)
        (write (string-append "-:~~=" gambit-root) out)
        (display " \"$@\"\n" out)))
    (invoke "chmod" ["+x" wrapper])
    wrapper))

(def (write-cli-wrapper!)
  (let ((wrapper (path-expand "bin/gerbil-scheme-harness" (build-prefix)))
        (gxi (gerbil-bin "gxi")))
    (create-directory* (path-directory wrapper))
    (call-with-output-file wrapper
      (lambda (out)
        (display "#!/bin/sh\nset -eu\n" out)
        (display "script_dir=$(CDPATH= cd \"$(dirname \"$0\")\" && pwd)\n" out)
        (display "root=$(CDPATH= cd \"$script_dir/../../..\" && pwd)\n" out)
        (display "if [ \"${GERBIL_LOADPATH:-}\" ]; then\n" out)
        (display "  export GERBIL_LOADPATH=\"$root/src:$GERBIL_LOADPATH\"\n" out)
        (display "else\n" out)
        (display "  export GERBIL_LOADPATH=\"$root/src\"\n" out)
        (display "fi\nexec " out)
        (write gxi out)
        (display " \"$root/bin/gerbil-scheme-harness.ss\" \"$@\"\n" out)))
    (invoke "chmod" ["+x" wrapper])
    wrapper))

(def (ensure-gerbil-gsc!)
  (unless (getenv "GERBIL_GSC" #f)
    (let ((default-gsc (path-expand "bin/gsc" (gerbil-home)))
          (homebrew-gsc (gerbil-bin "gsc")))
      (unless (file-exists? default-gsc)
        (when (file-exists? homebrew-gsc)
          (setenv "GERBIL_GSC"
                  (write-gsc-wrapper homebrew-gsc
                                     (path-normalize (path-expand ".." (gerbil-home))))))))))

(def (ensure-source-load-path!)
  (add-load-path! (path-expand "src" (current-directory))))

(ensure-gerbil-gsc!)
(ensure-source-load-path!)
(write-cli-wrapper!)

(defbuild-script
  '("src/cli")
  libdir: (path-expand "lib" (build-prefix))
  bindir: (path-expand "bin" (build-prefix))
  debug: #f)

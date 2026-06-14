#!/usr/bin/env gxi
;; -*- Gerbil -*-
(import :std/build-script
        :std/misc/process)

(def (build-prefix)
  (getenv "GERBIL_BUILD_PREFIX" (path-expand ".build/gerbil" (current-directory))))

(def (gerbil-bin name)
  (let ((usr-local-bin (string-append "/usr/local/bin/" name))
        (homebrew-bin (string-append "/opt/homebrew/bin/" name))
        (default-bin (path-expand (string-append "bin/" name) (gerbil-home)))
        (sibling-bin (path-expand (string-append "../bin/" name) (gerbil-home))))
    (cond
     ((file-exists? usr-local-bin) usr-local-bin)
     ((file-exists? homebrew-bin) homebrew-bin)
     ((file-exists? default-bin) default-bin)
     ((file-exists? sibling-bin) sibling-bin)
     (else name))))

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
  (let ((wrapper (path-expand "bin/gerbil-scheme-harness" (build-prefix))))
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
        (display "fi\n" out)
        (display "if [ \"${GERBIL:-}\" ]; then\n" out)
        (display "  GERBIL_BIN=\"$GERBIL\"\n" out)
        (display "elif command -v gxi >/dev/null 2>&1; then\n" out)
        (display "  GERBIL_BIN=$(command -v gxi)\n" out)
        (display "elif [ -x /usr/local/bin/gxi ]; then\n" out)
        (display "  GERBIL_BIN=/usr/local/bin/gxi\n" out)
        (display "elif [ -x /opt/homebrew/bin/gxi ]; then\n" out)
        (display "  GERBIL_BIN=/opt/homebrew/bin/gxi\n" out)
        (display "else\n" out)
        (display "  GERBIL_BIN=gxi\n" out)
        (display "fi\n" out)
        (display "exec \"$GERBIL_BIN\" \"$root/bin/gerbil-scheme-harness.ss\" \"$@\"\n" out)))
    (invoke "chmod" ["+x" wrapper])
    wrapper))

(def (ensure-gerbil-gsc!)
  (let (gsc (gerbil-bin "gsc"))
    (when (file-exists? gsc)
      (setenv "GERBIL_GSC"
              (write-gsc-wrapper gsc
                                 (path-normalize (gerbil-home)))))))

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

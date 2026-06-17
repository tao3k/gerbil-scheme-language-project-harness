;;; -*- Gerbil -*-
(def (shell-if condition body)
  (string-append "if [ " condition " ]; then\n" body "\nfi\n"))
(def (shell-exec command)
  (string-append "exec " command " \"$@\"\n"))
(def (write-wrapper out)
  (display "#!/bin/sh\nset -eu\n" out)
  (display "find src -name '*.ss' -print | xargs gxc\n" out))


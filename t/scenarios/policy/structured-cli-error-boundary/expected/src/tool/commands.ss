(import :std/cli/getopt
        :std/error
        :std/sugar)

(export main parse-args run-command)

(deferror-class ToolCommandError ())

(def (raise-tool-command-error message . irritants)
  (raise/context ToolCommandError message irritants))

(def +tool-command+
  (command 'tool
    help: "run policy and formatting commands"
    (command 'check
      help: "run policy checks"
      (option 'workspace "-w" "--workspace"
        help: "workspace path"
        default: ".")
      (option 'json "--json"
        help: "emit json output"))
    (command 'format
      help: "format Scheme files"
      (option 'workspace "-w" "--workspace"
        help: "workspace path"
        default: "."))))

(def (parse-args args)
  (parameterize ((current-getopt-parser +tool-command+))
    (try
     (getopt +tool-command+ args)
     (catch (getopt-error? e)
       (raise-tool-command-error "invalid command line" (getopt-error-e e))))))

(def (run-command command-options)
  (match command-options
    (['check . _] 0)
    (['format . _] 0)
    (_ (raise-tool-command-error "unknown command" command-options))))

(def (main . args)
  (with-exit-on-error
   (run-command (parse-args args))))

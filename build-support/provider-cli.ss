;;; -*- Gerbil -*-
;;; Provider executable materialization.

;;; Boundary:
;;; - Provider dispatch is generated as a native C executable by build.ss.
;;; - Fast routes are native-only; missing artifacts are build failures, not alternate runtime paths.

;;; Boundary:
;;; - Build materializers own parent-directory creation.
;;; - Returning the path keeps build.ss declarative and chainable.
;; : (-> Path String Path )
(def (write-file! path contents)
  (create-directory* (path-directory path))
  (call-with-output-file path
    (cut write-string contents <>))
  path)

;;; Boundary:
;;; - Datum files are the Scheme-facing side channel for generated wrappers.
;;; - A trailing newline keeps generated config diffs and diagnostics stable.
;; : (-> Path Datum Path )
(def (write-datum-file! path datum)
  (create-directory* (path-directory path))
  (call-with-output-file path
    (lambda (out)
      (write datum out)
      (newline out)))
  path)

;; : (-> Alist Symbol (Maybe Value) )
(def (config-ref config key)
  (let (entry (assoc key config))
    (and entry (cdr entry))))

;;; Boundary:
;;; - This manifest is the only place that binds generated wrapper artifacts.
;;; - The C dispatcher receives expanded paths and performs no repo discovery fallback.
;; : (-> Path Path Config )
(def (provider-cli-config binary harness-root)
  `((harness-root . ,harness-root)
    (fast-extension . ,(path-expand "gerbil-scheme-search-extension"
                                    (path-directory binary)))
    (fast-owner-items . ,(path-expand "gerbil-scheme-search-owner-items"
                                      (path-directory binary)))
    (guide-static-file . ,(path-expand "gerbil-scheme-guide-basic.txt"
                                       (path-directory binary)))
    (guide-static-all-file . ,(path-expand "gerbil-scheme-guide-all.txt"
                                           (path-directory binary)))
    (guide-static-policy-file . ,(path-expand "gerbil-scheme-guide-policy.txt"
                                              (path-directory binary)))
    (guide-static-extensions-file . ,(path-expand "gerbil-scheme-guide-extensions.txt"
                                                  (path-directory binary)))
    (guide-static-downstream-file . ,(path-expand "gerbil-scheme-guide-downstream.txt"
                                                  (path-directory binary)))
    (guide-static-poo-file . ,(path-expand "gerbil-scheme-guide-poo.txt"
                                           (path-directory binary)))
    (guide-static-exemplars-file . ,(path-expand "gerbil-scheme-guide-exemplars.txt"
                                                (path-directory binary)))
    (search-runtime . ,(path-expand
                        "src/search-fast/gerbil-scheme-search.ss"
                        harness-root))
    (harness-runtime . ,(path-expand
                         "bin/gerbil-scheme-harness.ss"
                         harness-root))))

;; : (-> Config Path Path )
(def (write-provider-static-guide-files! config harness-root)
  (let (output-dir (path-directory (config-ref config 'guide-static-file)))
    (create-directory* output-dir)
    (setenv "GERBIL_PATH" (path-expand ".gerbil" harness-root))
    (setenv "GERBIL_LOADPATH" (path-expand "src" harness-root))
    (invoke (getenv "GERBIL" "gxi")
            [(path-expand "build-support/static-guide-generator.ss"
                          harness-root)
             output-dir])
    output-dir))

;;; Boundary:
;;; - C source emission owns string escaping at the generator edge.
;;; - Callers pass semantic values, never pre-escaped C fragments.
;; : (-> String String )
(def (c-string value)
  (call-with-output-string ""
    (lambda (out)
      (write-char #\" out)
      (for-each
       (lambda (char)
         (cond
          ((char=? char #\\) (write-string "\\\\" out))
          ((char=? char #\") (write-string "\\\"" out))
          ((char=? char #\newline) (write-string "\\n" out))
          (else (write-char char out))))
       (string->list value))
      (write-char #\" out))))

;;; Boundary:
;;; - Writer procedures build generated source through one output-port protocol.
;;; - The generated C assembly stays composable instead of scattered string joins.
;; : (-> (-> OutputPort Unit) String )
(def (source-text write!)
  (call-with-output-string "" write!))

;; : (-> OutputPort String Unit )
(def (source-line! out text)
  (write-string text out)
  (newline out))

;; : (-> OutputPort Unit )
(def (source-blank! out)
  (newline out))

;;; Boundary:
;;; - Generated source blocks stay line-vector driven.
;;; - Newline policy is centralized here rather than repeated at each C fragment.
;; : (-> OutputPort (List String) Unit )
(def (source-lines! out lines)
  (for-each
   (lambda (line)
     (source-line! out line))
   lines))

;; : (-> OutputPort (List String) Unit )
(def (source-block! out lines)
  (source-lines! out lines)
  (source-blank! out))

;; : (-> OutputPort String Unit )
(def (write-c-include! out header)
  (source-line! out (string-append "#include <" header ">")))

;; : (-> OutputPort String String Unit )
(def (write-c-string-const! out name value)
  (source-line! out
                (string-append "static const char *"
                               name
                               " = "
                               (c-string value)
                               ";")))

;; : (List String )
(def +dispatcher-headers+
  ["errno.h" "stdio.h" "stdlib.h" "string.h" "unistd.h"])

;; : (List (Pair String Symbol) )
(def +dispatcher-config-constants+
  [(cons "harness_root" 'harness-root)
   (cons "fast_extension" 'fast-extension)
   (cons "guide_static_file" 'guide-static-file)
   (cons "guide_static_all_file" 'guide-static-all-file)
   (cons "guide_static_policy_file" 'guide-static-policy-file)
   (cons "guide_static_extensions_file" 'guide-static-extensions-file)
   (cons "guide_static_downstream_file" 'guide-static-downstream-file)
   (cons "guide_static_poo_file" 'guide-static-poo-file)
   (cons "guide_static_exemplars_file" 'guide-static-exemplars-file)
   (cons "search_runtime" 'search-runtime)
   (cons "harness_runtime" 'harness-runtime)])

;;; Boundary:
;;; - These C helper blocks are embedded runtime policy for the native dispatcher.
;;; - Keeping them data-shaped lets Scheme own assembly order without shell scripts.
;; : (List (List String) )
(def +dispatcher-helper-blocks+
  [["static int streq(const char *a, const char *b) { return a && b && strcmp(a, b) == 0; }"]
   ["static int has_arg(int argc, char **argv, const char *needle) {"
    "  for (int i = 1; i < argc; i++) if (streq(argv[i], needle)) return 1;"
    "  return 0;"
    "}"]
   ["static int executable_exists(const char *path) { return path && access(path, X_OK) == 0; }"]
   ["static void fail_missing_build_artifact(const char *label, const char *path) {"
    "  fprintf(stderr, \"missing required %s artifact: %s\\nrun `gxi build.ss compile` in %s\\n\", label, path ? path : \"<unknown>\", harness_root);"
    "  exit(127);"
    "}"]
   ["static void configure_env(void) {"
    "  char buffer[4096];"
    "  if (!getenv(\"GERBIL_PATH\")) { snprintf(buffer, sizeof(buffer), \"%s/.gerbil\", harness_root); setenv(\"GERBIL_PATH\", buffer, 1); }"
    "  if (!getenv(\"GERBIL_LOADPATH\")) { snprintf(buffer, sizeof(buffer), \"%s/src\", harness_root); setenv(\"GERBIL_LOADPATH\", buffer, 1); }"
    "}"]
   ["static void exec_forward(const char *program, int argc, char **argv, int start) {"
    "  int rest = argc - start;"
    "  char **next = calloc((size_t)rest + 2, sizeof(char *));"
    "  if (!next) { perror(\"calloc\"); exit(127); }"
    "  next[0] = (char *)program;"
    "  for (int i = 0; i < rest; i++) next[i + 1] = argv[start + i];"
    "  execvp(program, next);"
    "  perror(program);"
    "  exit(127);"
    "}"]
   ["static void exec_gerbil_runtime(const char *runtime, int argc, char **argv, int start) {"
    "  const char *gerbil = getenv(\"GERBIL\");"
    "  if (!gerbil || !*gerbil) gerbil = \"gxi\";"
    "  int rest = argc - start;"
    "  char **next = calloc((size_t)rest + 3, sizeof(char *));"
    "  if (!next) { perror(\"calloc\"); exit(127); }"
    "  next[0] = (char *)gerbil;"
    "  next[1] = (char *)runtime;"
    "  for (int i = 0; i < rest; i++) next[i + 2] = argv[start + i];"
    "  execvp(gerbil, next);"
    "  perror(gerbil);"
    "  exit(127);"
    "}"]
   ["static int emit_file(const char *path) {"
    "  FILE *file = fopen(path, \"rb\");"
    "  if (!file) return 0;"
    "  char buffer[8192];"
    "  size_t n;"
    "  while ((n = fread(buffer, 1, sizeof(buffer), file)) > 0) fwrite(buffer, 1, n, stdout);"
    "  fclose(file);"
    "  return 1;"
    "}"]
   ["static const char *arg_value(int argc, char **argv, const char *name) {"
    "  for (int i = 1; i + 1 < argc; i++) if (streq(argv[i], name)) return argv[i + 1];"
    "  return NULL;"
    "}"]
   ["static int parse_positive_long(const char *text, long *out) {"
    "  if (!text || !*text) return 0;"
    "  char *end = NULL;"
    "  errno = 0;"
    "  long value = strtol(text, &end, 10);"
    "  if (errno || !end || *end || value < 1) return 0;"
    "  *out = value;"
    "  return 1;"
    "}"]
   ["static int split_selector_range(const char *selector, char **path_out, long *start_out, long *end_out) {"
    "  char *copy = strdup(selector);"
    "  if (!copy) { perror(\"strdup\"); exit(127); }"
    "  long start = 0, end = 0;"
    "  char *last = strrchr(copy, ':');"
    "  if (!last) { *path_out = copy; *start_out = 0; *end_out = 0; return 1; }"
    "  char *range = last + 1;"
    "  *last = '\\0';"
    "  char *dash = strchr(range, '-');"
    "  if (dash) {"
    "    *dash = '\\0';"
    "    if (!parse_positive_long(range, &start) || !parse_positive_long(dash + 1, &end) || end < start) { free(copy); return 0; }"
    "    *path_out = copy; *start_out = start; *end_out = end; return 1;"
    "  }"
    "  char *prev = strrchr(copy, ':');"
    "  if (prev) {"
    "    char *start_text = prev + 1;"
    "    *prev = '\\0';"
    "    if (parse_positive_long(start_text, &start) && parse_positive_long(range, &end) && end >= start) {"
    "      *path_out = copy; *start_out = start; *end_out = end; return 1;"
    "    }"
    "    *prev = ':';"
    "  }"
    "  if (!parse_positive_long(range, &end)) { free(copy); return 0; }"
    "  *path_out = copy; *start_out = end; *end_out = end; return 1;"
    "}"]
   ["static void write_json_string_bytes(const char *text, size_t len) {"
    "  fputc('\"', stdout);"
    "  for (size_t i = 0; i < len; i++) {"
    "    unsigned char c = (unsigned char)text[i];"
    "    if (c == '\"' || c == '\\\\') { fputc('\\\\', stdout); fputc(c, stdout); }"
    "    else if (c == '\\n') fputs(\"\\\\n\", stdout);"
    "    else if (c == '\\r') fputs(\"\\\\r\", stdout);"
    "    else if (c == '\\t') fputs(\"\\\\t\", stdout);"
    "    else if (c < 0x20) fprintf(stdout, \"\\\\u%04x\", c);"
    "    else fputc(c, stdout);"
    "  }"
    "  fputc('\"', stdout);"
    "}"]
   ["static void emit_selector_range_or_exit(const char *selector, int json) {"
    "  char *path = NULL;"
    "  long start = 0, end = 0;"
    "  if (!split_selector_range(selector, &path, &start, &end)) {"
    "    fprintf(stderr, \"invalid selector: %s\\n\", selector ? selector : \"<missing>\");"
    "    exit(2);"
    "  }"
    "  FILE *file = fopen(path, \"rb\");"
    "  if (!file) { perror(path); free(path); exit(2); }"
    "  char *line = NULL;"
    "  size_t cap = 0;"
    "  ssize_t n = 0;"
    "  long current = 1;"
    "  if (json) { fputs(\"{\\\"selector\\\":\", stdout); write_json_string_bytes(selector, strlen(selector)); fputs(\",\\\"code\\\":\\\"\", stdout); }"
    "  while ((n = getline(&line, &cap, file)) != -1) {"
    "    if (!start || (current >= start && current <= end)) {"
    "      if (json) {"
    "        for (ssize_t i = 0; i < n; i++) {"
    "          char c = line[i];"
    "          if (c == '\"' || c == '\\\\') { fputc('\\\\', stdout); fputc(c, stdout); }"
    "          else if (c == '\\n') fputs(\"\\\\n\", stdout);"
    "          else if (c == '\\r') fputs(\"\\\\r\", stdout);"
    "          else if (c == '\\t') fputs(\"\\\\t\", stdout);"
    "          else if ((unsigned char)c < 0x20) fprintf(stdout, \"\\\\u%04x\", (unsigned char)c);"
    "          else fputc(c, stdout);"
    "        }"
    "      } else fwrite(line, 1, (size_t)n, stdout);"
    "    }"
    "    if (end && current > end) break;"
    "    current++;"
    "  }"
    "  if (json) fputs(\"\\\"}\\n\", stdout);"
    "  free(line);"
    "  fclose(file);"
    "  free(path);"
    "}"]
   ["static void route_query_selector_or_continue(int argc, char **argv, int start) {"
    "  const char *selector = arg_value(argc, argv, \"--selector\");"
    "  if (!selector) return;"
    "  emit_selector_range_or_exit(selector, has_arg(argc, argv, \"--json\"));"
    "  exit(0);"
    "}"]
   ["static const char *static_guide_file(int argc, char **argv, int start) {"
    "  const char *selected = guide_static_file;"
    "  int detail_seen = 0;"
    "  for (int i = start; i < argc; i++) {"
    "    if (streq(argv[i], \"--workspace\") || streq(argv[i], \"--view\")) { if (++i >= argc) return NULL; continue; }"
    "    if (streq(argv[i], \"--\")) continue;"
    "    if (streq(argv[i], \"--all\")) { if (detail_seen++) return NULL; selected = guide_static_all_file; continue; }"
    "    if (streq(argv[i], \"--policy\")) { if (detail_seen++) return NULL; selected = guide_static_policy_file; continue; }"
    "    if (streq(argv[i], \"--extensions\") || streq(argv[i], \"--extension\")) { if (detail_seen++) return NULL; selected = guide_static_extensions_file; continue; }"
    "    if (streq(argv[i], \"--downstream\")) { if (detail_seen++) return NULL; selected = guide_static_downstream_file; continue; }"
    "    if (streq(argv[i], \"--poo\")) { if (detail_seen++) return NULL; selected = guide_static_poo_file; continue; }"
    "    if (streq(argv[i], \"--exemplars\") || streq(argv[i], \"--exemplar\")) { if (detail_seen++) return NULL; selected = guide_static_exemplars_file; continue; }"
    "    return NULL;"
    "  }"
    "  return selected;"
    "}"]
   ["static void route_guide_or_fail(int argc, char **argv, int start) {"
    "  const char *path = static_guide_file(argc, argv, start);"
    "  if (path && emit_file(path)) exit(0);"
    "  fail_missing_build_artifact(\"static guide\", path);"
    "}"]
   ["int main(int argc, char **argv) {"
    "  configure_env();"
    "  if (argc > 3 && streq(argv[1], \"search\") && streq(argv[2], \"extension\") && (streq(argv[3], \"poo\") || streq(argv[3], \"gerbil-poo\")) && !has_arg(argc, argv, \"--json\")) {"
    "    if (!executable_exists(fast_extension)) fail_missing_build_artifact(\"native extension\", fast_extension);"
    "    exec_forward(fast_extension, argc, argv, 3);"
    "  }"
    "  if (argc > 4 && streq(argv[1], \"search\") && streq(argv[2], \"owner\") && streq(argv[4], \"items\") && !has_arg(argc, argv, \"--json\") && !has_arg(argc, argv, \"--code\")) {"
    "    return owner_items_native_main(argc, argv);"
    "  }"
    "  if (argc > 2 && streq(argv[1], \"search\") && streq(argv[2], \"guide\")) route_guide_or_fail(argc, argv, 3);"
    "  if (argc > 1 && streq(argv[1], \"guide\") && !has_arg(argc, argv, \"--code\")) route_guide_or_fail(argc, argv, 2);"
    "  if (argc > 2 && streq(argv[1], \"query\")) route_query_selector_or_continue(argc, argv, 2);"
    "  if (argc > 1 && streq(argv[1], \"search\")) exec_gerbil_runtime(search_runtime, argc, argv, 2);"
    "  exec_gerbil_runtime(harness_runtime, argc, argv, 1);"
    "}"]])

;;; Boundary:
;;; - Include emission owns the generated C prelude and native owner-items hook.
;;; - Later sections can assume declarations are already present.
;; : (-> OutputPort Unit )
(def (write-dispatcher-includes! out)
  (for-each
   (lambda (header)
     (write-c-include! out header))
   +dispatcher-headers+)
  (source-blank! out)
  (source-line! out "int owner_items_native_main(int argc, char **argv);")
  (source-blank! out))

;;; Boundary:
;;; - Dispatcher config constants are copied from the Scheme manifest.
;;; - Missing config keys should fail in Scheme before C source is compiled.
;; : (-> OutputPort Config Unit )
(def (write-dispatcher-config! out config)
  (for-each
   (lambda (entry)
     (write-c-string-const! out
                            (car entry)
                            (config-ref config (cdr entry))))
   +dispatcher-config-constants+)
  (source-blank! out))

;;; Boundary:
;;; - Helper block emission preserves the route order encoded in data.
;;; - The generator controls composition; C strings only carry runtime mechanics.
;; : (-> OutputPort Unit )
(def (write-dispatcher-helpers! out)
  (for-each
   (lambda (block)
     (source-block! out block))
   +dispatcher-helper-blocks+))

;;; Boundary:
;;; - Native dispatcher source is assembled from prelude, manifest, and helper blocks.
;;; - The build step writes one coherent C translation unit for the provider binary.
;; : (-> Config String )
(def (native-dispatcher-source-text config)
  (source-text
   (lambda (out)
     (write-dispatcher-includes! out)
     (write-dispatcher-config! out config)
     (write-dispatcher-helpers! out))))

;; : (-> Path Config Path )
(def (write-provider-native-dispatcher-source! path config)
  (write-file! path (native-dispatcher-source-text config)))

;; : (-> Path Path Path )
(def (write-provider-cli-config! binary harness-root)
  (let* ((config-path (string-append binary ".config"))
         (config (provider-cli-config binary harness-root)))
    (write-datum-file! config-path config)
    (write-provider-static-guide-files! config harness-root)
    config-path))

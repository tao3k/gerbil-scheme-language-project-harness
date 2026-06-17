;;; -*- Gerbil -*-
;;; Provider executable materialization.

;;; Boundary:
;;; - Provider dispatch is generated as a native C executable by build.ss.
;;; - Fast routes are native-only; missing artifacts are build failures, not alternate runtime paths.

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

;; Any <- Alist Symbol
(def (config-ref config key)
  (let (entry (assoc key config))
    (and entry (cdr entry))))

;; Config <- Path Path
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

;; Path <- Config Path
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

(def (source-text write!)
  (call-with-output-string "" write!))

(def (source-line! out text)
  (write-string text out)
  (newline out))

(def (source-blank! out)
  (newline out))

(def (source-lines! out lines)
  (for-each
   (lambda (line)
     (source-line! out line))
   lines))

(def (source-block! out lines)
  (source-lines! out lines)
  (source-blank! out))

(def (write-c-include! out header)
  (source-line! out (string-append "#include <" header ">")))

(def (write-c-string-const! out name value)
  (source-line! out
                (string-append "static const char *"
                               name
                               " = "
                               (c-string value)
                               ";")))

(def +dispatcher-headers+
  ["errno.h" "stdio.h" "stdlib.h" "string.h" "unistd.h"])

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
    "  if (argc > 1 && streq(argv[1], \"search\")) exec_gerbil_runtime(search_runtime, argc, argv, 2);"
    "  exec_gerbil_runtime(harness_runtime, argc, argv, 1);"
    "}"]])

(def (write-dispatcher-includes! out)
  (for-each
   (lambda (header)
     (write-c-include! out header))
   +dispatcher-headers+)
  (source-blank! out)
  (source-line! out "int owner_items_native_main(int argc, char **argv);")
  (source-blank! out))

(def (write-dispatcher-config! out config)
  (for-each
   (lambda (entry)
     (write-c-string-const! out
                            (car entry)
                            (config-ref config (cdr entry))))
   +dispatcher-config-constants+)
  (source-blank! out))

(def (write-dispatcher-helpers! out)
  (for-each
   (lambda (block)
     (source-block! out block))
   +dispatcher-helper-blocks+))

(def (native-dispatcher-source-text config)
  (source-text
   (lambda (out)
     (write-dispatcher-includes! out)
     (write-dispatcher-config! out config)
     (write-dispatcher-helpers! out))))

;; Path <- Path Config
(def (write-provider-native-dispatcher-source! path config)
  (write-file! path (native-dispatcher-source-text config)))

;; Path <- Path Path
(def (write-provider-cli-config! binary harness-root)
  (let* ((config-path (string-append binary ".config"))
         (config (provider-cli-config binary harness-root)))
    (write-datum-file! config-path config)
    (write-provider-static-guide-files! config harness-root)
    config-path))

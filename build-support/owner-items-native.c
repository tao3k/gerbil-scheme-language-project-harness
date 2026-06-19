#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  char *kind;
  char *name;
  int line;
  int package_item;
} item_t;

static int streq(const char *a, const char *b) {
  return a && b && strcmp(a, b) == 0;
}

static int has_arg(int argc, char **argv, const char *needle) {
  for (int i = 1; i < argc; i++) if (streq(argv[i], needle)) return 1;
  return 0;
}

static const char *option_value(int argc, char **argv, const char *key) {
  for (int i = 1; i + 1 < argc; i++) if (streq(argv[i], key)) return argv[i + 1];
  return NULL;
}

static int option_int(int argc, char **argv, const char *key, int fallback) {
  const char *value = option_value(argc, argv, key);
  return value ? atoi(value) : fallback;
}

static int option_takes_value(const char *arg) {
  return streq(arg, "--workspace") || streq(arg, "--query") ||
         streq(arg, "--limit") || streq(arg, "--view");
}

static char **positionals(int argc, char **argv, int *out_count) {
  char **items = calloc((size_t)argc, sizeof(char *));
  int count = 0;
  for (int i = 1; i < argc; i++) {
    if (option_takes_value(argv[i])) { i++; continue; }
    if (strncmp(argv[i], "--", 2) == 0) continue;
    items[count++] = argv[i];
  }
  *out_count = count;
  return items;
}

static char *join_path(const char *root, const char *path) {
  if (!path || path[0] == '/') return strdup(path);
  size_t n = strlen(root) + strlen(path) + 2;
  char *out = malloc(n);
  snprintf(out, n, "%s/%s", root, path);
  return out;
}

static const char *base_name(const char *path) {
  const char *slash = path ? strrchr(path, '/') : NULL;
  return slash ? slash + 1 : path;
}

static int basename_eq(const char *path, const char *name) {
  const char *base = base_name(path);
  return base && streq(base, name);
}

static char *read_file_text(const char *path) {
  FILE *file = fopen(path, "rb");
  if (!file) return NULL;
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return NULL;
  }
  long size = ftell(file);
  if (size < 0) {
    fclose(file);
    return NULL;
  }
  rewind(file);
  char *text = malloc((size_t)size + 1);
  if (!text) {
    fclose(file);
    return NULL;
  }
  size_t read = fread(text, 1, (size_t)size, file);
  text[read] = 0;
  fclose(file);
  return text;
}

static char *trim_left(char *line) {
  while (*line && isspace((unsigned char)*line)) line++;
  return line;
}

static int symbol_char(int c) {
  return c && !isspace((unsigned char)c) && c != ')' && c != '(' &&
         c != '[' && c != ']' && c != '"' && c != ';';
}

static char *copy_symbol(const char *start) {
  const char *end = start;
  while (symbol_char((unsigned char)*end)) end++;
  size_t n = (size_t)(end - start);
  char *out = malloc(n + 1);
  memcpy(out, start, n);
  out[n] = 0;
  return out;
}

static char *copy_string_token(const char *start) {
  const char *end = start;
  while (*end && *end != '"') end++;
  size_t n = (size_t)(end - start);
  char *out = malloc(n + 1);
  memcpy(out, start, n);
  out[n] = 0;
  return out;
}

static char *package_name_from_text(const char *text) {
  const char *package = text ? strstr(text, "(package:") : NULL;
  if (!package) return NULL;
  const char *cursor = package + strlen("(package:");
  while (*cursor && isspace((unsigned char)*cursor)) cursor++;
  if (*cursor == '"') return copy_string_token(cursor + 1);
  if (symbol_char((unsigned char)*cursor)) return copy_symbol(cursor);
  return NULL;
}

static int package_line_from_text(const char *text) {
  const char *package = text ? strstr(text, "(package:") : NULL;
  if (!package) return 1;
  int line = 1;
  for (const char *cursor = text; cursor < package; cursor++) {
    if (*cursor == '\n') line++;
  }
  return line;
}

static int def_head(const char *line, const char **kind_out, const char **after_out) {
  static const char *heads[] = {
    "def", "def*", "define", "define-values", "define-syntax",
    "defstruct", "defclass", ".defclass", "defsyntax",
    "defsyntax-for-match", "defrules", "defrule", "defalias",
    "define-type", "defmethod", ".defmethod", "defgeneric",
    ".defgeneric", "defprotocol", ".defprotocol", "defcompile-method"
  };
  if (*line != '(') return 0;
  line++;
  for (size_t i = 0; i < sizeof(heads) / sizeof(heads[0]); i++) {
    size_t n = strlen(heads[i]);
    if (strncmp(line, heads[i], n) == 0 && isspace((unsigned char)line[n])) {
      *kind_out = heads[i];
      *after_out = line + n;
      return 1;
    }
  }
  return 0;
}

static char *definition_name(const char *after) {
  while (*after && isspace((unsigned char)*after)) after++;
  if (*after == '(' || *after == '[') {
    after++;
    while (*after && isspace((unsigned char)*after)) after++;
  }
  if (!symbol_char((unsigned char)*after)) return NULL;
  return copy_symbol(after);
}

static int term_match(const char *value, char **terms, int term_count) {
  if (term_count == 0) return 1;
  if (!value) return 0;
  for (int i = 0; i < term_count; i++) {
    if (terms[i] && strstr(value, terms[i])) return 1;
  }
  return 0;
}

static int package_match(const char *owner, const char *name, const char *content,
                         char **terms, int term_count) {
  return term_match(owner, terms, term_count) ||
         term_match("gerbil.pkg", terms, term_count) ||
         term_match("package", terms, term_count) ||
         term_match("package:", terms, term_count) ||
         term_match(name, terms, term_count) ||
         term_match(content, terms, term_count);
}

static char **split_terms(const char *query, int *out_count) {
  char **terms = calloc(64, sizeof(char *));
  int count = 0;
  if (!query || !*query) { *out_count = 0; return terms; }
  char *copy = strdup(query);
  for (char *tok = strtok(copy, " \t\r\n|"); tok && count < 64; tok = strtok(NULL, " \t\r\n|")) {
    terms[count++] = strdup(tok);
  }
  free(copy);
  *out_count = count;
  return terms;
}

int owner_items_native_main(int argc, char **argv) {
  if (has_arg(argc, argv, "--json") || has_arg(argc, argv, "--code")) {
    fprintf(stderr, "fast owner-items does not handle --json/--code\n");
    return 2;
  }

  int positional_count = 0;
  char **pos = positionals(argc, argv, &positional_count);
  int offset = positional_count > 0 && streq(pos[0], "search") ? 1 : 0;
  if (positional_count < offset + 3 || !streq(pos[offset], "owner") ||
      !streq(pos[offset + 2], "items")) {
    fprintf(stderr, "fast owner-items requires `search owner <path> items`\n");
    return 2;
  }

  const char *owner = pos[offset + 1];
  const char *root = option_value(argc, argv, "--workspace");
  if (!root) root = ".";
  char *path = join_path(root, owner);
  FILE *file = fopen(path, "r");
  if (!file) {
    perror(path);
    return 1;
  }

  int term_count = 0;
  char **terms = split_terms(option_value(argc, argv, "--query"), &term_count);
  int limit = option_int(argc, argv, "--limit", 80);
  if (limit < 0) limit = 80;
  int names_only = has_arg(argc, argv, "--names-only");

  item_t *items = calloc(1024, sizeof(item_t));
  int count = 0;
  if (basename_eq(owner, "gerbil.pkg") && count < 1024) {
    char *content = read_file_text(path);
    if (content) {
      char *name = package_name_from_text(content);
      if (!name) name = strdup("package");
      if (package_match(owner, name, content, terms, term_count)) {
        items[count].kind = strdup("package");
        items[count].name = name;
        items[count].line = package_line_from_text(content);
        items[count].package_item = 1;
        count++;
      } else {
        free(name);
      }
      free(content);
    }
  }

  char *line = NULL;
  size_t cap = 0;
  int line_no = 0;
  while (getline(&line, &cap, file) != -1 && count < 1024) {
    line_no++;
    char *trimmed = trim_left(line);
    const char *kind = NULL;
    const char *after = NULL;
    if (!def_head(trimmed, &kind, &after)) continue;
    char *name = definition_name(after);
    if (!name) continue;
    char selector[4096];
    snprintf(selector, sizeof(selector), "%s:%d-%d", owner, line_no, line_no);
    if (term_match(name, terms, term_count) || term_match(kind, terms, term_count) ||
        term_match(selector, terms, term_count)) {
      items[count].kind = strdup(kind);
      items[count].name = name;
      items[count].line = line_no;
      items[count].package_item = 0;
      count++;
    } else {
      free(name);
    }
  }
  free(line);
  fclose(file);

  int shown = count < limit ? count : limit;
  if (!names_only) printf("[gerbil-owner-items] path=%s matches=%d shown=%d limit=%d\n", owner, count, shown, limit);
  for (int i = 0; i < shown; i++) {
    if (names_only) {
      printf("%s\n", items[i].name);
    } else {
      if (items[i].package_item) {
        printf("|item kind=%s name=%s selector=%s:%d-%d source=native-parser languageKind=package-form role=package\n",
               items[i].kind, items[i].name, owner, items[i].line, items[i].line);
      } else {
        printf("|item kind=%s name=%s selector=%s:%d-%d\n",
               items[i].kind, items[i].name, owner, items[i].line, items[i].line);
      }
    }
  }
  return 0;
}

#ifndef OWNER_ITEMS_NATIVE_NO_MAIN
int main(int argc, char **argv) {
  return owner_items_native_main(argc, argv);
}
#endif

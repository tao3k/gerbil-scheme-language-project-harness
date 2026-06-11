# Gerbil Source Notes

Research source: `.data/gerbil` from `https://git.cons.io/mighty-gerbils/gerbil`
at commit `add92248`.

Gerbil is a Scheme dialect on top of Gambit. The user-facing tools in
`src/gerbil/main.ss` include `gxi`, `gxc`, `gxpkg`, `gxtest`, `gxtags`,
`gxprof`, and ensemble/httpd helpers. The harness is implemented in Gerbil and
uses Gerbil reader/expander APIs as the parser boundary.

Useful first-pass native facts:

- Source files are primarily `.ss`, `.ssi`, and `.scm`.
- Package roots commonly contain `gerbil.pkg` and `build.ss`.
- Module headers use plain top-level fields such as `prelude:`, `package:`,
  and `namespace:`.
- Dependency edges are visible in top-level `(import ...)` forms with Gerbil
  module ids like `:std/error` and relative string imports like
  `"core/runtime"`.
- Public surface is visible in `(export ...)`, but macro expansion is required
  for complete phase-aware export facts.
- Common owner items are introduced through `def`, `defstruct`, `defclass`,
  `defsyntax`, `defrules`, `defalias`, `defmethod`, `defcompile-method`,
  `define`, `define-values`, and `define-syntax`.

First-pass harness boundary:

1. Build a workspace index from `.ss`, `.ssi`, `.scm`, `.sld`, and `gerbil.pkg`.
2. Use `core-read-module` for ordinary Gerbil modules so module id, prelude,
   namespace, source locations, and body forms come from the native expander.
3. Use `read-syntax-from-file` or syntax-only `#lang` fallback when importing a
   project prelude would execute project reader code during search.
4. Extract package/prelude/namespace/import/export/include/definition facts.
5. Expose the common search/query/check/agent surfaces used by the other
   language harnesses.
6. Keep compiler/type enrichment as the next step: use `import-module`,
   module-context exports, and compiler facts only where the command explicitly
   needs expanded/phase-aware semantics.

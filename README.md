# Gerbil Scheme Language Project Harness

This repository is the Gerbil Scheme language provider for
`agent-semantic-protocols`.

The implementation is pure Gerbil/Scheme. Parser authority comes from Gerbil's
native reader and expander data:

- `read-syntax-from-file` reads source with the Gerbil readtable.
- `stx-source` gives source locations for top-level forms.
- `syntax->datum` is used only as the compact projection layer for search and
  query packets.
- Future export/type enrichment should use `import-module` and module-context
  facts, following Gerbil's own `gxtags` pattern.

No Python parser is part of this harness.

## Commands

Use an explicit Gerbil binary when it is not on `PATH`:

```sh
GERBIL_LOADPATH=$PWD/src /opt/homebrew/opt/gerbil-scheme/bin/gxi bin/gerbil-scheme-harness search prime --view seeds .
GERBIL_LOADPATH=$PWD/src /opt/homebrew/opt/gerbil-scheme/bin/gxi bin/gerbil-scheme-harness search owner src/std/misc/uuid.ss --view seeds .
GERBIL_LOADPATH=$PWD/src /opt/homebrew/opt/gerbil-scheme/bin/gxi bin/gerbil-scheme-harness search owner src/std/misc/uuid.ss items --query uuid --names-only .
GERBIL_LOADPATH=$PWD/src /opt/homebrew/opt/gerbil-scheme/bin/gxi bin/gerbil-scheme-harness query src/std/misc/uuid.ss --term random-uuid --workspace . --code
GERBIL_LOADPATH=$PWD/src /opt/homebrew/opt/gerbil-scheme/bin/gxi bin/gerbil-scheme-harness check --full .
GERBIL_LOADPATH=$PWD/src /opt/homebrew/opt/gerbil-scheme/bin/gxi bin/gerbil-scheme-harness agent doctor --json .
```

After `gxpkg build`, the installed entrypoint is expected to be
`gerbil-scheme-harness`.

## Alignment Target

This first native version aligns the common provider surface:

- compact text by default
- JSON for protocol consumers
- `search workspace`, `prime`, `owner`, `owner items`, `symbol`, `import`,
  `fzf`, and `ingest`
- parser-owned `query --term`, `query --names-only`, and `query --code`
- source-preserved `query --from-hook direct-source-read --selector ... --code`
- `check --changed` and `check --full`
- `agent doctor --json`
- `agent guide`

The next implementation layer should enrich this with expanded module exports,
phase-aware import/export facts, and compiler/type facts from Gerbil's expander
and compiler modules.


# Gerbil Scheme Language Project Harness
This repository is the Gerbil Scheme language provider for `agent-semantic-protocols`.
The implementation is pure Gerbil/Scheme. Parser authority comes from Gerbil's native reader and expander data:
- `read-syntax-from-file` reads source with the Gerbil readtable.
- `stx-source` gives source locations for top-level forms.
- `syntax->datum` is used only as the compact projection layer for search and query packets.
- Future export/type enrichment should use `import-module` and module-context facts, following Gerbil's own `gxtags` pattern.
No Python parser is part of this harness.
## Commands
Build the repository-local provider wrapper from the harness root:
```sh
./build-native.ss
./.bin/gslph guide --downstream
```
After the native build, the provider entrypoint is `gslph`.
## Downstream gxtest Quickstart
Install this harness from its checkout into the global Gerbil package store:
```sh
gxpkg build
```
Downstream packages should depend on the installed harness package in `gerbil.pkg`:
```scheme
(package: your/package
 depend: ("github.com/tao3k/gerbil-scheme-language-project-harness"))
```
Add a small `gxtest` fixture, for example `t/project-policy-test.ss`:
```scheme
;;; -*- Gerbil -*-
(import :std/test
        :policy/gxtest)
(export project-policy-test)
(def project-policy-test
  (make-project-policy-test "."))
```
Then run:
```sh
gxtest t/project-policy-test.ss
```
Gerbil package-manager state belongs under the global `~/.gerbil` store. Do not create or commit a repository-local `.gerbil` directory for this harness. For the full onboarding contract, see `docs/60-69-user/60.01-downstream-gxtest-onboarding.org`.
## Alignment Target
This first native version aligns the common provider surface:
- compact text by default
- `agent doctor --json` provider metadata for protocol consumers
- `search workspace`, `prime`, `owner`, `owner items`, `symbol`, `import`, `fzf`, and `ingest`
- parser-owned `query --term`, `query --names-only`, and `query --code`
- source-preserved `query --from-hook direct-source-read --selector ... --code`
- `check --changed` and `check --full`
- `agent doctor --json`
- `agent guide`
The next implementation layer should enrich this with expanded module exports, phase-aware import/export facts, and compiler/type facts from Gerbil's expander and compiler modules.

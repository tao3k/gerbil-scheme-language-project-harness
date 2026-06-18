# Policy Scenarios

Each policy scenario is a directory fixture consumed by `src/scenario`.

- `input/` is the project tree before the agent-facing repair.
- `expected/` is the project tree after the repair.
- Snapshot tests should call the scenario runner; they should not synthesize
  fixture files with test-local writer functions.

Use `harness-dependency-policy-application/` as the downstream `gerbil.pkg`
interface example: it shows a project depending on this harness and applying
local `agent-policy` rule filters from package metadata.

Use `harness-dependency-policy-disable-requires-explanation/` as the escape
guard example: it shows that `disabled-rules:` without `explanation:` is not
applied and must be repaired into a documented local exception.

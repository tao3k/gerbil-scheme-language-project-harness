# Policy Scenarios

Each policy scenario is a directory fixture consumed by `src/scenario`.

- `input/` is the project tree before the agent-facing repair.
- `expected/` is the project tree after the repair.
- Snapshot tests should call the scenario runner; they should not synthesize
  fixture files with test-local writer functions.


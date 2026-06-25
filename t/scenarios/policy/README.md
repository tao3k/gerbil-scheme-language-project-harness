# Policy Scenarios

Each policy scenario is a directory fixture consumed by `src/scenario`.

Scenarios are not just trigger fixtures. They are the evidence loop for the
policy philosophy in `docs/50-59-policy/51.00-policy-philosophy.org`: policy
should help an agent write better Gerbil Scheme without hardcoding a single
rewrite. A scenario should show the low-quality agent-authored shape, one
idiomatic repair, and the boundary where that repair would be misuse.

- `input/` is the project tree before the agent-facing repair.
- `expected/` is the project tree after the repair.
- Snapshot tests should call the scenario runner; they should not synthesize
  fixture files with test-local writer functions.
- Style scenarios should include benchmark metadata for optimization focus,
  quality axes, and misuse guards when the policy could otherwise overreach.

Use `harness-dependency-policy-application/` as the downstream `gerbil.pkg`
interface example: it shows a project depending on this harness and applying
local `agent-policy` rule filters from package metadata.

Use `harness-dependency-policy-disable-requires-explanation/` as the escape
guard example: it shows that `disabled-rules:` without `explanation:` is not
applied and must be repaired into a documented local exception.

# Harness Dependency Policy Application

This scenario is the downstream user interface for applying the Gerbil Scheme
project harness from `gerbil.pkg`.

- `input/gerbil.pkg` depends on the harness. Agent policy rules are enabled by
  default, so the project receives the typed-combinator-style finding for the
  source shape in `src/orders/core.ss`.
- `expected/gerbil.pkg` keeps the same dependency but disables
  `GERBIL-SCHEME-AGENT-POLICY-013` with a required `explanation:`, so the same source
  tree is accepted by the package policy filter without giving agents a silent
  escape hatch.

Use this shape when a downstream project wants the harness installed as a
package dependency while explicitly documenting why a local policy rule is
disabled.

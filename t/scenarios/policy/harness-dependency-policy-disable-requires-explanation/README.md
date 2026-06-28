# Harness Dependency Policy Disable Requires Explanation

This scenario documents the escape guard for downstream `gerbil.pkg` policy.

- `input/gerbil.pkg` disables `GERBIL-SCHEME-AGENT-POLICY-013` without an
  `explanation:`. The disable is ignored and the project receives both the
  package-policy error and the original R013 finding.
- `expected/gerbil.pkg` adds an explicit explanation, so the local exception is
  applied and R013 is filtered.

Use this scenario when an agent needs to understand that disabling a policy rule
is a documented local exception, not a silent escape path.

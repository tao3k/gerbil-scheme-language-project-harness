(policyScenario
 (id "harness-dependency-policy-disable-requires-explanation")
 (before
  (package
   ((dependencies
     ("github.com/tao3k/agent-semantic-protocols/languages/gerbil-scheme-language-project-harness"))
    (default "all-rules-enabled")
    (disabledRules ("GERBIL-SCHEME-AGENT-R013"))
    (explanation #f)))
  (policyFinding
   ("GERBIL-SCHEME-AGENT-R024"
    "gerbil.pkg"
    "gerbil.pkg"
    "agent-policy disabled-rules requires a non-empty explanation; rule disables without rationale are ignored so agents cannot escape policy gates"))
  (styleFinding
   ("GERBIL-SCHEME-AGENT-R013"
    "src/orders/core.ss"
    "src/orders/core.ss"
    "Scheme source owner has 2 definitions but only 0 adjacent typed-combinator-style algebraic contracts; 2 public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches")))
 (after
  (package
   ((dependencies
     ("github.com/tao3k/agent-semantic-protocols/languages/gerbil-scheme-language-project-harness"))
    (default "all-rules-enabled")
    (disabledRules ("GERBIL-SCHEME-AGENT-R013"))
    (explanation
     "Downstream example intentionally leaves legacy order helpers unrepaired while documenting the local exception.")))
  (r024Findings ())
  (r013Findings ())))

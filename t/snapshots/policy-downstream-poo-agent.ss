(policyScenario
 (id "downstream-poo-agent")
 (findings
  (("GERBIL-SCHEME-AGENT-R004"
    "src/orders/core.ss"
    "src/orders/core.ss:3-3"
    "definition process is too vague for agent-written Gerbil; name the domain or data flow")
   ("GERBIL-SCHEME-AGENT-R006"
    "src/orders/io.ss"
    "src/orders/io.ss:3-3"
    "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first")
   ("GERBIL-SCHEME-AGENT-R007"
    "src/orders/io.ss"
    "src/orders/io.ss"
    "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified"))))

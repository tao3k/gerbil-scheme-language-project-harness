(policyScenario
 (id "downstream-poo-agent")
 (findings
  (("GERBIL-SCHEME-AGENT-POLICY-004"
    "src/orders/core.ss"
    "src/orders/core.ss:3-3"
    "definition process is too vague for agent-written Gerbil; name the domain or data flow")
   ("GERBIL-SCHEME-AGENT-POLICY-006"
    "src/orders/io.ss"
    "src/orders/io.ss:3-3"
    "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first")
   ("GERBIL-SCHEME-AGENT-POLICY-007"
    "src/orders/io.ss"
    "src/orders/io.ss"
    "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified")
   ("GERBIL-SCHEME-AGENT-POLICY-010"
    "src/orders/core.ss"
    "src/orders/core.ss:4-4"
    "manual object constructor make-order uses hash while POO/protocol capability is active; prefer parser-owned defclass/defgeneric/defmethod or cite why a raw data record is intentional")
   ("GERBIL-SCHEME-AGENT-POLICY-008"
    "src/orders/io.ss"
    "src/orders/io.ss:3-3"
    "POO method :wr is missing parser-owned defgeneric,defclass-or-defprotocol facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")
   ("GERBIL-SCHEME-AGENT-POLICY-013"
    "src/orders/core.ss"
    "src/orders/core.ss"
    "Scheme source owner has 3 definitions but only 0 adjacent typed-combinator-style algebraic contracts; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches")
   ("GERBIL-SCHEME-AGENT-POLICY-015"
    "src/orders/core.ss"
    "src/orders/core.ss"
    "1 key comment locations need engineering comments beyond typed contracts")
   ("GERBIL-SCHEME-AGENT-POLICY-015"
    "src/orders/io.ss"
    "src/orders/io.ss"
    "2 key comment locations need engineering comments beyond typed contracts")
   ("GERBIL-SCHEME-AGENT-POLICY-018"
    "src/orders/io.ss"
    "src/orders/io.ss:2-2"
    "runtime import :clan/poo/io is not explicit enough; use (only-in :clan/poo/io <symbols...>) after checking owner usage"))))

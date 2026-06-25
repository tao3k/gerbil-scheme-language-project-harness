(policyScenario
 (id "poo-prototype-fixed-point")
 (before (finding ("GERBIL-SCHEME-AGENT-R026"
                   "src/orders/core.ss"
                   "src/orders/core.ss:9-9"
                   "POO constructor make-order projects 3 slots with .ref; prefer prototype-local composition with {(:: @ super) slot: ...}, =>, =>.+, ?, and .mix so the object fixed point stays in one POO shape"))
         (guidance
          ((mode "soft-warning")
           (trigger "constructor projection burst")
           (allowedUse
            "isolated .ref/.@/.get boundary reads are valid POO API usage")
           (repairShape
            "define a base prototype and refine slots inside {(:: @ super) ...}; use => for slot transforms, =>.+ for object merges, ? for defaults, and .mix for instance materialization")
           (docsPath
            "docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org")
           (preferredSyntax "{(:: @ super) slot: ...}, =>, =>.+, ?, .mix"))))
 (after (r026Findings ())))

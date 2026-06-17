;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent repair policy tests.

(import :std/test
        (only-in :std/text/json read-json)
        :policy/fixtures)

(export agent-repair-policy-test)

;; PolicyTest
(def agent-repair-policy-test
  (test-suite "gerbil scheme harness agent repair policy"
    (test-case "agent policy check json exposes grouped repair phases"
      (let* ((root ".run/policy-functional-idiom-check-json")
             (_ (write-functional-idiom-project root))
             (result (policy-check-output ["--json" root]))
             (packet (call-with-input-string (cdr result) read-json))
             (agent-repair (hash-get packet "agentRepair"))
             (repair-plan (hash-get agent-repair "repairPlan"))
             (finding-groups (hash-get agent-repair "findingGroups"))
             (comment-group
              (find (lambda (group)
                      (member "GERBIL-SCHEME-AGENT-R015"
                              (hash-get group "rules")))
                    finding-groups))
             (comment-plan (hash-get comment-group "repairPlan"))
             (comment-phases (hash-get comment-plan "repairPhases"))
             (finding (json-finding-by-rule
                       (hash-get packet "findings")
                       "GERBIL-SCHEME-AGENT-R009"))
             (comment-finding (json-finding-by-rule
                               (hash-get packet "findings")
                               "GERBIL-SCHEME-AGENT-R015"))
             (finding-repair (hash-get finding "agentRepair")))
        (check (car result) => 1)
        (check (hash-get agent-repair "status") => "active")
        (check (hash-get agent-repair "repairableFindings") => 3)
        (check (hash-get agent-repair "repairableWarnings") => 3)
        (check (hash-get agent-repair "repairableErrors") => 0)
        (check (hash-get agent-repair "trigger") => "warning")
        (check (hash-get repair-plan "status") => "active")
        (check (> (hash-get repair-plan "groupCount") 0) => #t)
        (check (not (not comment-group)) => #t)
        (check (not (not (member "functionQualityProfile"
                                  (hash-get comment-group "requiredWitnesses"))))
               => #t)
        (check (hash-get comment-group "multiPolicy") => #t)
        (check (hash-get comment-group "repairStrategy")
               => "multi-policy-structural-first")
        (check (hash-get comment-plan "strategy")
               => "multi-policy-structural-first")
        (check (length comment-phases) => 2)
        (check (hash-get (car comment-phases) "name")
               => "primary-shape")
        (check (hash-get (cadr comment-phases) "name")
               => "dependent-comment-rationale")
        (check (hash-get (cadr comment-phases) "rules")
               => ["GERBIL-SCHEME-AGENT-R015"])
        (check (hash-get comment-plan "commentRepairOrder")
               => "comment-quality repairs run after structural/style repairs when both hit the same group")
        (check (hash-get finding-repair "repairable") => #t)
        (check (hash-get finding-repair "active") => #t)
        (check (hash-get finding-repair "trigger") => "warning")
        (check (hash-get finding-repair "guideTopic")
               => "functional-data-transform")
        (check (hash-get finding-repair "guideIntent") => "repair")
        (check (hash-get finding-repair "action") => "inspect-code-shape")
        (check (hash-get finding-repair "guideCodeFlag") => "--code")
        (check (hash-get finding-repair "nextCommand")
               => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair")
        (check (hash-get (hash-get comment-finding "agentRepair")
                         "nextCommand")
               => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style")))))

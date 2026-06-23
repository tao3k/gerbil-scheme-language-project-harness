;;; -*- Gerbil -*-
(import :clan/poo)

(def (build-report-profile)
  (object<-alist
   [["id" . "orders"]
    ["title" . "Orders"]
    ["owner" . "agent"]
    ["status" . "hot"]
    ["summary" . "compile pressure"]
    ["rows" . 8]
         ["columns" . 5]
         ["sections" . 3]
         ["charts" . 2]
         ["filters" . 4]
         ["exports" . 2]
         ["alerts" . 6]
         ["retries" . 3]
         ["sla" . "99.9"]
         ["region" . "global"]
         ["priority" . "high"]]))

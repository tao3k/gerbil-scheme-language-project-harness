(import :std/encoding/json/writer
        :std/format/writer
        :std/sugar)

(export write-report write-report-row)

(def (write-report-row writer row)
  (writer.write-json-object-begin writer)
  (writer.write-json-field writer 'path (hash-ref row 'path ""))
  (writer.write-coma writer)
  (writer.write-json-field writer 'status (hash-ref row 'status "unknown"))
  (writer.write-coma writer)
  (writer.write-json-field writer 'findings (hash-ref row 'findings 0))
  (writer.write-json-object-end writer))

(defjson-writer ReportRow
  write-report-row)

(def (write-report writer rows)
  (writer.write-json-object-begin writer)
  (writer.write-symbol/string writer 'rows)
  (writer.write-colon writer)
  (writer.write-lbracket writer)
  (let loop ((rest rows) (first? #t))
    (unless (null? rest)
      (unless first?
        (writer.write-coma writer))
      (write-report-row writer (car rest))
      (loop (cdr rest) #f)))
  (writer.write-rbrance writer)
  (writer.write-json-object-end writer))

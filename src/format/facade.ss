;;; -*- Gerbil -*-
;;; Formatting facade for command and library callers.

(import :format/core
        :format/files)

(export fmt-target-files
        fmt-file
        fmt-result-changed?
        fmt-format-text
        fmt-format-lines
        fmt-trim-right
        fmt-source-file?)

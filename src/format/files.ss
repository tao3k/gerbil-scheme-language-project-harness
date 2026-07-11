;;; -*- Gerbil -*-
;;; Formatter file discovery and write application.

(import :gerbil/gambit
        :gslph/src/format/core
        (only-in :std/misc/path path-expand)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map)
        :gslph/src/support/io)

(export fmt-target-files
        fmt-file
        fmt-result-changed?)

(def +fmt-ignored-dirs+
  '("." ".." ".cache" ".devenv" ".git" ".gerbil" ".run"
    "build" "dist" "node_modules" "scenarios" "snapshots" "target" "tree-sitter"))

;; fmt-target-files
;;   : (-> String (List String) (List Path))
;;   | result sorted formatter source files under explicit targets or project root
;;   | doc m%
;;       `fmt-target-files root targets` expands command targets into a stable
;;       list of Gerbil source files. Empty targets mean the project root.
;;
;;       # Examples
;;
;;       ```scheme
;;       (fmt-target-files "." ["src"])
;;       ;; => sorted .ss/.scm files under src
;;       ```
;;     %
(def (fmt-target-files root targets)
  (sort
   (if (pair? targets)
     (append-map (lambda (target)
                   (fmt-target-paths root target))
                 targets)
     (fmt-directory-source-files root "."))
   string<?))

;; : (-> String String (List Path))
(def (fmt-target-paths root target)
  (let (path (path-expand target root))
    (cond
     ((not (file-exists? path)) [])
     ((eq? (file-type path) 'directory)
      (fmt-directory-source-files root target))
     ((fmt-source-file? target) [target])
     (else []))))

;; : (-> String String (List Path))
(def (fmt-directory-source-files root relpath)
  (let (directory (path-expand relpath root))
    (with-catch
     (lambda (_) [])
     (lambda ()
       (append-map
        (lambda (entry)
          (fmt-directory-entry-source-files root relpath entry))
        (sort (directory-files directory) string<?))))))

;; : (-> String String String (List Path))
(def (fmt-directory-entry-source-files root relpath entry)
  (if (member entry +fmt-ignored-dirs+)
    []
    (let* ((child (fmt-child-path relpath entry))
           (path (path-expand child root)))
      (cond
       ((eq? (file-type path) 'directory)
        (fmt-directory-source-files root child))
       ((fmt-source-file? child) [child])
       (else [])))))

;; : (-> String String String)
(def (fmt-child-path relpath entry)
  (if (or (string=? relpath "")
          (string=? relpath "."))
    entry
    (string-append relpath "/" entry)))

;; fmt-file
;;   : (-> String String Boolean FmtResult)
;;   | result pair of relative path and whether formatting would change content
;;   | doc m%
;;       `fmt-file root relpath check?` applies RS7 formatting to one source
;;       file. In check mode it reports drift without writing.
;;
;;       # Examples
;;
;;       ```scheme
;;       (fmt-file "." "src/core.ss" #t)
;;       ;; => ("src/core.ss" . #f)
;;       ```
;;     %
(def (fmt-file root relpath check?)
  (let* ((path (path-expand relpath root))
         (original (read-source-text path))
         (formatted (fmt-format-text original))
         (changed? (not (string=? original formatted))))
    (when (and changed? (not check?))
      (write-source-text path formatted))
    (cons relpath changed?)))

;; : (-> FmtResult Boolean)
(def (fmt-result-changed? result)
  (cdr result))

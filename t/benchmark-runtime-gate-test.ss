;;; -*- Gerbil -*-
;;; Runtime benchmark gates for the installed/check command path.

(import :gerbil/gambit
        :std/test
        (only-in :commands/check check-main)
        (rename-in :cli-release-linker (main launcher-main))
        (only-in :std/misc/process run-process)
        (only-in :support/time monotonic-ms duration-ms)
        :benchmark/gate)

(export benchmark-runtime-gate-test)

;; Relpath
(def +check-cache-gate-root+
  (path-expand ".cache/agent-semantic-protocol/test/check-cache-gate"
               (current-directory)))

;; Relpath
(def +check-cache-gate-cache-path+
  (path-expand ".cache/agent-semantic-protocol/gerbil-scheme/check/text.sexp"
               +check-cache-gate-root+))

(def +changed-empty-gate-root+
  (path-expand ".cache/agent-semantic-protocol/test/check-changed-empty-gate"
               (current-directory)))

;; Relpath
;; Integer
(def +check-cache-gate-max-warm-ms+ 100)

;; Integer
(def +check-cache-gate-max-launcher-warm-ms+ 100)

;;; Boundary:
;;; - Empty changed-scope launcher checks measured 135-191ms on the package
;;;   runtime path; keep the gate subsecond while avoiding scheduler noise.
;; : Integer
(def +check-cache-gate-max-launcher-changed-ms+ 250)

;;; Boundary:
;;; - The POO scenario contract fast gate measured 4.7-7.1s after removing
;;;   selected gxtest recompilation. Keep the guard below 15s so regressions
;;;   to the previous 40s+ path fail loudly.
;; : Integer
;; trim-trailing-slashes
;;   : (-> String String)
;;   | doc m%
;;       `trim-trailing-slashes path` normalizes a directory path before the
;;       recursive fixture creator checks parents.
;;     %
(def (trim-trailing-slashes path)
  (let loop ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (loop (- end 1))
      (substring path 0 end))))

;; : (-> Path Void)
(def (ensure-directory* path)
  (when path
    (let (dir (trim-trailing-slashes path))
      (unless (or (string=? dir "")
                  (string=? dir ".")
                  (file-exists? dir))
        (let (parent (path-directory dir))
          (when (and parent
                     (not (string=? parent dir)))
            (ensure-directory* parent)))
        (unless (file-exists? dir)
          (create-directory dir))))))

;; : (-> Path Void)
(def (delete-file* path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> Path String Void)
(def (write-text-file path text)
  (delete-file* path)
  (ensure-directory* (path-directory path))
  (call-with-output-file path
    (lambda (out) (display text out))))

;; : (-> Void)
(def (prepare-check-cache-gate-project!)
  (ensure-directory* +check-cache-gate-root+)
  (ensure-directory* (path-expand "src" +check-cache-gate-root+))
  (delete-file* +check-cache-gate-cache-path+)
  (write-text-file
   (path-expand "gerbil.pkg" +check-cache-gate-root+)
   ";;; Boundary:\n;;; - Package fixture isolates cache replay from source discovery drift.\n;;; - Keep the runtime scope to one deterministic source module.\n(package: check-cache-gate)\n")
  (write-text-file
   (path-expand "src/core.ss" +check-cache-gate-root+)
   ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - Cache gate fixture keeps one deterministic runtime export.\n;;; - No IO, macro expansion, or dynamic imports belong in this timing scope.\n(import :gerbil/gambit)\n(export add1*)\n;;; Boundary:\n;;; - add1* is intentionally pure so full-check timing measures cache replay.\n;;; - Preserve this helper as a single arithmetic operation.\n;; : (-> Integer Integer)\n(def (add1* n) (+ n 1))\n"))

;; : (-> Void)
(def (prepare-changed-empty-gate-project!)
  (ensure-directory* +changed-empty-gate-root+)
  (write-text-file
   (path-expand "README.md" +changed-empty-gate-root+)
   "non-gerbil change\n")
  (run-process ["git" "init"]
               directory: +changed-empty-gate-root+
               stdout-redirection: #t
               stderr-redirection: #t
               check-status: void))

;; : (-> (-> Integer) Alist)
(def (run-check-command/silent thunk)
  (let* ((start-ms (monotonic-ms))
         (status
          (parameterize ((current-output-port (open-output-string)))
            (thunk)))
         (elapsed-ms (duration-ms start-ms (monotonic-ms))))
    (list (cons 'status status)
          (cons 'elapsedMs elapsed-ms))))

;; run-check-command/silent/best
;;   : (-> Integer (-> Integer) Alist)
;;   | doc m%
;;       `run-check-command/silent/best attempts thunk` returns the fastest
;;       successful timing receipt from a small repeated benchmark window.
;;     %
(def (run-check-command/silent/best attempts thunk)
  (if (<= attempts 0)
    (error "check benchmark attempts must be positive" attempts)
    (let loop ((remaining attempts) (best #f))
      (if (zero? remaining)
        best
        (let (receipt (run-check-command/silent thunk))
          (loop (- remaining 1)
                (if (or (not best)
                        (< (benchmark-fixture-ref receipt 'elapsedMs)
                           (benchmark-fixture-ref best 'elapsedMs)))
                  receipt
                  best)))))))

;; : (-> Path Alist)
(def (run-check-full/silent root)
  (run-check-command/silent
   (lambda ()
     (check-main ["--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-check-full/silent/best root)
  (run-check-command/silent/best
   3
   (lambda ()
     (check-main ["--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-launcher-check-full/silent/best root)
  (run-check-command/silent/best
   3
   (lambda ()
     (apply launcher-main ["check" "--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-launcher-check-changed/silent root)
  (run-check-command/silent/best
   3
   (lambda ()
     (apply launcher-main ["check" "changed" "--view" "seeds" root]))))

;; : (-> Alist)
;; : TestSuite
(def benchmark-runtime-gate-test
  (test-suite "gerbil scheme runtime benchmark gate"
    (test-case "check full cache stays in millisecond budget"
      (prepare-check-cache-gate-project!)
      (let* ((cold (run-check-full/silent +check-cache-gate-root+))
             (warm (run-check-full/silent/best +check-cache-gate-root+))
             (launcher-warm
              (run-launcher-check-full/silent/best +check-cache-gate-root+)))
        (check (benchmark-fixture-ref cold 'status) => 0)
        (check (benchmark-fixture-ref warm 'status) => 0)
        (check (benchmark-fixture-ref launcher-warm 'status) => 0)
        (check (< (benchmark-fixture-ref warm 'elapsedMs)
                  +check-cache-gate-max-warm-ms+)
               => #t)
        (check (< (benchmark-fixture-ref launcher-warm 'elapsedMs)
                  +check-cache-gate-max-launcher-warm-ms+)
               => #t)))

    (test-case "check changed empty Gerbil scope stays in launcher millisecond budget"
      (prepare-changed-empty-gate-project!)
      (let (changed (run-launcher-check-changed/silent +changed-empty-gate-root+))
        (check (benchmark-fixture-ref changed 'status) => 0)
        (check (< (benchmark-fixture-ref changed 'elapsedMs)
                  +check-cache-gate-max-launcher-changed-ms+)
               => #t)))))

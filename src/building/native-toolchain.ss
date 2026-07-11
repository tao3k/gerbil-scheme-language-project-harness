;;; Boundary: native compiler environment policy belongs to Building, never to callers.
(import :gerbil/gambit)

(export native-toolchain
        native-toolchain?
        make-native-toolchain
        native-toolchain-sdkroot
        native-toolchain-developer-dir
        native-toolchain-default
        with-native-toolchain)

;; : (-> String String NativeToolchain)
(defstruct native-toolchain (sdkroot developer-dir))

;; : (-> NativeToolchain)
(def (native-toolchain-default)
  (make-native-toolchain "" ""))

;; : (-> String Any String)
(def (native-toolchain-value name value)
  (if (string? value)
    value
    (error "native toolchain values must be strings" name value)))

;; : (-> NativeToolchain Procedure Any)
(def (with-native-toolchain toolchain thunk)
  (unless (native-toolchain? toolchain)
    (error "expected native toolchain" toolchain))
  (let ((previous-sdkroot (getenv "SDKROOT" #f))
        (previous-developer-dir (getenv "DEVELOPER_DIR" #f))
        (sdkroot (native-toolchain-value
                  "SDKROOT"
                  (native-toolchain-sdkroot toolchain)))
        (developer-dir (native-toolchain-value
                        "DEVELOPER_DIR"
                        (native-toolchain-developer-dir toolchain))))
    (dynamic-wind
      (lambda ()
        (setenv "SDKROOT" sdkroot)
        (setenv "DEVELOPER_DIR" developer-dir))
      thunk
      (lambda ()
        (setenv "SDKROOT" (or previous-sdkroot ""))
        (setenv "DEVELOPER_DIR" (or previous-developer-dir ""))))))

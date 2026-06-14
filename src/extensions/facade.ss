;;; -*- Gerbil -*-
;;; Stable extension facade for Gerbil package capability facts.

(import :extensions/core
        :extensions/model
        :extensions/poo)

(export extension-fact
        make-extension-fact
        extension-fact?
        extension-fact-name
        extension-fact-activation
        extension-fact-dependency-mode
        extension-fact-package-manager
        extension-fact-package
        extension-fact-dependencies
        extension-fact-capabilities
        extension-fact-json
        extension-fact-search-line
        project-extension-facts
        project-extension-search-lines
        project-extension-json
        poo-extension-active?
        poo-extension-fact
        poo-registered-extension-facts
        poo-registered-extension-query?
        poo-extension-capability-names
        poo-extension-search-lines
        poo-extension-json
        poo-source-ref
        poo-pattern-evidence
        poo-pattern-query?
        poo-pattern-focus
        poo-pattern-selectors
        poo-pattern-minimal-forms
        poo-pattern-failure-cases)

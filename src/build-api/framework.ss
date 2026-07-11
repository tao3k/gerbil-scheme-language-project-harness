;;; Boundary: the package-facing Build API re-exports the Building Framework POO model.
;;; Invariant: this facade preserves pure stage planning; package receipt persistence stays in Build API owners.
(import ../building/facade
        :gslph/src/building/commands)

(export build-stage
        build-stage?
        make-build-stage
        build-stage-label
        build-stage-kind
        build-stage-spec
        build-stage-current-pred
        build-stage-runner
        build-stage-after
        build-stage-description
        build-stage-receipt
        build-stage-receipt?
        make-build-stage-receipt
        build-stage-receipt-label
        build-stage-receipt-kind
        build-stage-receipt-status
        build-stage-receipt-description
        build-stage-receipt-result
        build-stage-receipt-elapsed-jiffies
        build-stage-receipt->alist
        build-plan-receipts->alist
        build-stage-status
        build-stage-run!
        build-plan-run!
        std-builder
        std-builder?
        make-std-builder
        std-builder-name
        std-builder-make-proc
        std-builder-stage-kind
        std-builder-description
        std-builder-srcdir
        std-builder-make-options
        default-std-builder
        std-builder-effective-options
        std-builder-run-spec!
        std-builder-stage
        (import: :gslph/src/building/commands))

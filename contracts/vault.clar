;; VaultNest Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-vault-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-locked (err u103))
(define-constant err-invalid-signer (err u104))

;; Data structures
(define-map vaults
  { owner: principal }
  {
    balance: uint,
    lock-until: uint,
    recovery-address: (optional principal),
    signers: (list 5 principal),
    required-signatures: uint,
    metadata: (optional (string-ascii 256))
  }
)

;; Events
(define-data-var last-vault-event (string-ascii 50) "")

;; Create new vault
(define-public (create-vault (recovery-address (optional principal)) (required-sigs uint) (metadata (optional (string-ascii 256))))
  (let ((vault-exists (get-vault-data tx-sender)))
    (if (is-some vault-exists)
      (err err-vault-not-found)
      (begin
        (var-set last-vault-event (concat "vault_created_" (to-ascii tx-sender)))
        (ok (map-set vaults
          { owner: tx-sender }
          {
            balance: u0,
            lock-until: u0,
            recovery-address: recovery-address,
            signers: (list tx-sender),
            required-signatures: required-sigs,
            metadata: metadata
          }
        )))
      )
    )
)

;; Deposit STX
(define-public (deposit (amount uint))
  (let ((vault-data (get-vault-data tx-sender)))
    (match vault-data
      vault 
      (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set last-vault-event (concat "deposit_" (to-ascii amount)))
        (ok (map-set vaults
          { owner: tx-sender }
          {
            balance: (+ amount (get balance vault)),
            lock-until: (get lock-until vault),
            recovery-address: (get recovery-address vault),
            signers: (get signers vault),
            required-signatures: (get required-signatures vault),
            metadata: (get metadata vault)
          })))
      (err err-vault-not-found))
    )
)

;; Withdraw STX
(define-public (withdraw (amount uint))
  (let ((vault-data (get-vault-data tx-sender)))
    (match vault-data 
      vault 
      (if (> (get lock-until vault) block-height)
        (err err-locked)
        (if (>= (get balance vault) amount)
          (begin
            (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
            (var-set last-vault-event (concat "withdraw_" (to-ascii amount)))
            (ok (map-set vaults
              { owner: tx-sender }
              {
                balance: (- (get balance vault) amount),
                lock-until: (get lock-until vault),
                recovery-address: (get recovery-address vault),
                signers: (get signers vault),
                required-signatures: (get required-signatures vault),
                metadata: (get metadata vault)
              })))
          (err err-insufficient-balance)))
      (err err-vault-not-found))
    )
)

;; Read-only functions
(define-read-only (get-vault-data (owner principal))
  (map-get? vaults { owner: owner })
)

(define-read-only (get-last-event)
  (var-get last-vault-event)
)

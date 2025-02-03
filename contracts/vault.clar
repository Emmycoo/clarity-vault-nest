;; VaultNest Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-vault-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-locked (err u103))

;; Data structures
(define-map vaults
  { owner: principal }
  {
    balance: uint,
    lock-until: uint,
    recovery-address: (optional principal),
    signers: (list 5 principal)
  }
)

;; Create new vault
(define-public (create-vault (recovery-address (optional principal)))
  (let ((vault-exists (get-vault-data tx-sender)))
    (if (is-some vault-exists)
      (err err-vault-not-found)
      (ok (map-set vaults
        { owner: tx-sender }
        {
          balance: u0,
          lock-until: u0,
          recovery-address: recovery-address,
          signers: (list tx-sender)
        }
      ))
    )
  )
)

;; Deposit assets
(define-public (deposit (amount uint))
  (let ((vault-data (get-vault-data tx-sender)))
    (match vault-data
      vault (ok (map-set vaults
        { owner: tx-sender }
        {
          balance: (+ amount (get balance vault)),
          lock-until: (get lock-until vault),
          recovery-address: (get recovery-address vault),
          signers: (get signers vault)
        }))
      (err err-vault-not-found)
    )
  )
)

;; Withdraw assets
(define-public (withdraw (amount uint))
  (let ((vault-data (get-vault-data tx-sender)))
    (match vault-data 
      vault (if (> (get lock-until vault) block-height)
        (err err-locked)
        (if (>= (get balance vault) amount)
          (ok (map-set vaults
            { owner: tx-sender }
            {
              balance: (- (get balance vault) amount),
              lock-until: (get lock-until vault),
              recovery-address: (get recovery-address vault),
              signers: (get signers vault)
            }))
          (err err-insufficient-balance)))
      (err err-vault-not-found)
    )
  )
)

;; Read-only functions
(define-read-only (get-vault-data (owner principal))
  (map-get? vaults { owner: owner })
)

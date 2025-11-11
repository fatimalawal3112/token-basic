;; basic-token-extended.clar
;; A clean, error-free fungible token with advanced features
;; Features added:
;; - Owner-only mint
;; - Burn tokens
;; - Allowances (approve, transfer-from)
;; - Balance + allowance getters
;; - Total supply

(define-data-var total-supply uint u0)
(define-data-var owner principal tx-sender)

(define-map balances { user: principal } { amount: uint })
(define-map allowances { owner: principal, spender: principal } { amount: uint })

(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_INSUFFICIENT_FUNDS u200)
(define-constant ERR_NOT_ALLOWED u300)
(define-constant ERR_OVERFLOW u400)

;; Private function to safely add checked numbers
(define-private (safe-add (a uint) (b uint))
  (let ((sum (+ a b)))
    (if (or (is-eq a u0) (>= sum a))
        (ok sum)
        (err ERR_OVERFLOW))))

;; Private function to safely subtract checked numbers
(define-private (safe-sub (a uint) (b uint))
  (if (>= a b)
      (ok (- a b))
      (err ERR_INSUFFICIENT_FUNDS)))

;; ---------------------------------------------------
;; HELPERS
;; ---------------------------------------------------

;; Safe uint arithmetic
(define-read-only (get-balance (user principal))
  (default-to u0 (get amount (map-get? balances { user: user })))
)

(define-read-only (is-owner)
  (is-eq tx-sender (var-get owner))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-allowance (token-owner principal) (spender principal))
  (default-to u0 (get amount (map-get? allowances { owner: token-owner, spender: spender })))
)

;; ---------------------------------------------------
;; MINT (OWNER ONLY)
;; ---------------------------------------------------

(define-public (mint (recipient principal) (amount uint))
  (if (not (is-owner))
      (err ERR_NOT_OWNER)
      (let ((balance (get-balance recipient)))
        (let ((new-balance (+ balance amount)))
          (asserts! (>= new-balance balance) (err ERR_OVERFLOW))
          (let ((new-supply (+ (var-get total-supply) amount)))
            (asserts! (>= new-supply (var-get total-supply)) (err ERR_OVERFLOW))
            (begin
              (map-set balances { user: recipient } { amount: new-balance })
              (var-set total-supply new-supply)
              (ok true)))))))

;; ---------------------------------------------------
;; BURN TOKENS
;; ---------------------------------------------------

(define-public (burn (amount uint))
  (let ((balance (get-balance tx-sender)))
    (asserts! (>= balance amount) (err ERR_INSUFFICIENT_FUNDS))
    (begin
      (map-set balances { user: tx-sender } { amount: (- balance amount) })
      (var-set total-supply (- (var-get total-supply) amount))
      (ok true))))

;; ---------------------------------------------------
;; DIRECT TRANSFER
;; ---------------------------------------------------

(define-public (transfer (recipient principal) (amount uint))
  (let ((sender-balance (get-balance tx-sender))
        (recipient-balance (get-balance recipient)))
    (asserts! (>= sender-balance amount) (err ERR_INSUFFICIENT_FUNDS))
    (asserts! (>= (+ recipient-balance amount) recipient-balance) (err ERR_INSUFFICIENT_FUNDS))
    (begin
      (map-set balances { user: tx-sender } { amount: (- sender-balance amount) })
      (map-set balances { user: recipient } { amount: (+ recipient-balance amount) })
      (ok true))))

;; ---------------------------------------------------
;; ALLOWANCE + TRANSFER-FROM
;; ---------------------------------------------------

(define-read-only (check-allowance (token-owner principal) (spender principal))
  (default-to u0 
    (get amount 
      (map-get? allowances { owner: token-owner, spender: spender })))
)

;; Set allowance for spender
(define-public (approve (spender principal) (amount uint))
  (let ((key { owner: tx-sender, spender: spender })
        (value { amount: amount }))
    (map-set allowances key value)
    (ok true)))

(define-public (transfer-from (token-owner principal) (recipient principal) (amount uint))
  (let ((allowance (check-allowance token-owner tx-sender))
        (owner-balance (get-balance token-owner))
        (recipient-balance (get-balance recipient)))
    (asserts! (>= allowance amount) (err ERR_NOT_ALLOWED))
    (asserts! (>= owner-balance amount) (err ERR_INSUFFICIENT_FUNDS))
    (asserts! (>= (+ recipient-balance amount) recipient-balance) (err ERR_INSUFFICIENT_FUNDS))
    (begin
      (map-set balances { user: token-owner } { amount: (- owner-balance amount) })
      (map-set balances { user: recipient } { amount: (+ recipient-balance amount) })
      (map-set allowances { owner: token-owner, spender: tx-sender } { amount: (- allowance amount) })
      (ok true))))

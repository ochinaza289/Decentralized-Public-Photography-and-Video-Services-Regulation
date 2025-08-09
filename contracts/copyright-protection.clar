;; Copyright Protection Contract
;; Helps photographers protect intellectual property rights

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-ALREADY-EXISTS (err u401))
(define-constant ERR-NOT-FOUND (err u402))
(define-constant ERR-INVALID-INPUT (err u403))
(define-constant ERR-DISPUTE-ACTIVE (err u404))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u405))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Registration fee (in microSTX)
(define-constant REGISTRATION-FEE u100000)

;; Dispute resolution fee
(define-constant DISPUTE-FEE u500000)

;; Work types
(define-constant TYPE-PHOTOGRAPH u1)
(define-constant TYPE-VIDEO u2)
(define-constant TYPE-DIGITAL-ART u3)

;; Data structures
(define-map copyright-holders
  { holder: principal }
  {
    name: (string-ascii 100),
    email: (string-ascii 100),
    verified: bool,
    registered-at: uint
  }
)

(define-map copyrighted-works
  { work-id: uint }
  {
    owner: principal,
    title: (string-ascii 200),
    work-type: uint,
    creation-date: uint,
    registration-date: uint,
    hash: (buff 32),
    license-terms: (string-ascii 500),
    public: bool
  }
)

(define-map licensing-agreements
  { work-id: uint, licensee: principal }
  {
    license-type: (string-ascii 50),
    start-date: uint,
    end-date: uint,
    fee-paid: uint,
    terms: (string-ascii 300),
    active: bool
  }
)

(define-map copyright-disputes
  { dispute-id: uint }
  {
    work-id: uint,
    claimant: principal,
    respondent: principal,
    description: (string-ascii 500),
    status: (string-ascii 20),
    filed-at: uint,
    resolved-at: (optional uint)
  }
)

(define-data-var next-work-id uint u1)
(define-data-var next-dispute-id uint u1)

;; Register as copyright holder
(define-public (register-copyright-holder (name (string-ascii 100)) (email (string-ascii 100)))
  (let ((holder tx-sender))
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len email) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? copyright-holders { holder: holder })) ERR-ALREADY-EXISTS)

    (map-set copyright-holders
      { holder: holder }
      {
        name: name,
        email: email,
        verified: false,
        registered-at: block-height
      }
    )
    (ok true)
  )
)

;; Register copyrighted work
(define-public (register-work (title (string-ascii 200)) (work-type uint) (creation-date uint) (work-hash (buff 32)) (license-terms (string-ascii 500)) (public bool))
  (let (
    (owner tx-sender)
    (work-id (var-get next-work-id))
  )
    (asserts! (is-some (map-get? copyright-holders { holder: owner })) ERR-NOT-FOUND)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (<= work-type TYPE-DIGITAL-ART) ERR-INVALID-INPUT)
    (asserts! (<= creation-date block-height) ERR-INVALID-INPUT)
    (asserts! (>= (stx-get-balance owner) REGISTRATION-FEE) ERR-INSUFFICIENT-PAYMENT)

    ;; Transfer registration fee
    (try! (stx-transfer? REGISTRATION-FEE owner (as-contract tx-sender)))

    ;; Register the work
    (map-set copyrighted-works
      { work-id: work-id }
      {
        owner: owner,
        title: title,
        work-type: work-type,
        creation-date: creation-date,
        registration-date: block-height,
        hash: work-hash,
        license-terms: license-terms,
        public: public
      }
    )

    (var-set next-work-id (+ work-id u1))
    (ok work-id)
  )
)

;; Create licensing agreement
(define-public (create-license (work-id uint) (licensee principal) (license-type (string-ascii 50)) (duration-blocks uint) (fee uint) (terms (string-ascii 300)))
  (let ((work (unwrap! (map-get? copyrighted-works { work-id: work-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner work)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len license-type) u0) ERR-INVALID-INPUT)
    (asserts! (> duration-blocks u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? licensing-agreements { work-id: work-id, licensee: licensee })) ERR-ALREADY-EXISTS)
    (asserts! (>= (stx-get-balance licensee) fee) ERR-INSUFFICIENT-PAYMENT)

    ;; Transfer license fee
    (try! (stx-transfer? fee licensee (get owner work)))

    ;; Create licensing agreement
    (map-set licensing-agreements
      { work-id: work-id, licensee: licensee }
      {
        license-type: license-type,
        start-date: block-height,
        end-date: (+ block-height duration-blocks),
        fee-paid: fee,
        terms: terms,
        active: true
      }
    )

    (ok true)
  )
)

;; File copyright dispute
(define-public (file-dispute (work-id uint) (respondent principal) (description (string-ascii 500)))
  (let (
    (claimant tx-sender)
    (dispute-id (var-get next-dispute-id))
    (work (unwrap! (map-get? copyrighted-works { work-id: work-id }) ERR-NOT-FOUND))
  )
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (not (is-eq claimant respondent)) ERR-INVALID-INPUT)
    (asserts! (>= (stx-get-balance claimant) DISPUTE-FEE) ERR-INSUFFICIENT-PAYMENT)

    ;; Transfer dispute fee
    (try! (stx-transfer? DISPUTE-FEE claimant (as-contract tx-sender)))

    ;; File dispute
    (map-set copyright-disputes
      { dispute-id: dispute-id }
      {
        work-id: work-id,
        claimant: claimant,
        respondent: respondent,
        description: description,
        status: "pending",
        filed-at: block-height,
        resolved-at: none
      }
    )

    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

;; Resolve dispute (admin only)
(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 20)) (winner principal))
  (let ((dispute (unwrap! (map-get? copyright-disputes { dispute-id: dispute-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status dispute) "pending") ERR-INVALID-INPUT)
    (asserts! (or (is-eq winner (get claimant dispute)) (is-eq winner (get respondent dispute))) ERR-INVALID-INPUT)

    ;; Update dispute status
    (map-set copyright-disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: resolution,
        resolved-at: (some block-height)
      })
    )

    ;; Return dispute fee to winner
    (try! (stx-transfer? DISPUTE-FEE (as-contract tx-sender) winner))

    (ok true)
  )
)

;; Transfer work ownership
(define-public (transfer-ownership (work-id uint) (new-owner principal))
  (let ((work (unwrap! (map-get? copyrighted-works { work-id: work-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner work)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? copyright-holders { holder: new-owner })) ERR-NOT-FOUND)

    (map-set copyrighted-works
      { work-id: work-id }
      (merge work { owner: new-owner })
    )

    (ok true)
  )
)

;; Verify copyright holder (admin only)
(define-public (verify-copyright-holder (holder principal))
  (let ((holder-info (unwrap! (map-get? copyright-holders { holder: holder }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set copyright-holders
      { holder: holder }
      (merge holder-info { verified: true })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-copyright-holder (holder principal))
  (map-get? copyright-holders { holder: holder })
)

(define-read-only (get-work (work-id uint))
  (map-get? copyrighted-works { work-id: work-id })
)

(define-read-only (get-license (work-id uint) (licensee principal))
  (map-get? licensing-agreements { work-id: work-id, licensee: licensee })
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? copyright-disputes { dispute-id: dispute-id })
)

(define-read-only (is-license-active (work-id uint) (licensee principal))
  (match (map-get? licensing-agreements { work-id: work-id, licensee: licensee })
    license (and
      (get active license)
      (> (get end-date license) block-height)
    )
    false
  )
)

(define-read-only (get-next-work-id)
  (var-get next-work-id)
)

(define-read-only (get-next-dispute-id)
  (var-get next-dispute-id)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

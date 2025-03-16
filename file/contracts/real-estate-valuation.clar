;; Real Estate Valuation Smart Contract
;; This contract serves as the main entry point for the real estate valuation system.
;; It integrates with property registry and valuation logic to provide on-chain property valuations.

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PARAMETERS (err u102))
(define-constant ERR_PROPERTY_ALREADY_EXISTS (err u103))

;; Data maps
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    location-hash: (buff 32),
    square-footage: uint,
    bedroom-count: uint,
    bathroom-count: uint,
    year-built: uint,
    last-sale-price: uint,
    last-sale-timestamp: uint,
    last-valuation: uint,
    last-valuation-timestamp: uint
  }
)

(define-map property-valuations
  { property-id: uint }
  { valuation-history: (list 10 (tuple (method (string-utf8 20)) (timestamp uint) (value uint))) }
)

;; Helper functions - Fixed to avoid circular dependencies
(define-read-only (simple-pow (base uint) (exp uint))
  (fold pow-iter (list u1 base exp) u1)
)

(define-read-only (pow-iter (prev uint) (params (list 3 uint)))
  (let (
    (result prev)
    (base (get 1 params))
    (remaining-exp (get 2 params))
  )
    (if (> remaining-exp u0)
      (* result base)
      result
    )
  )
)

(define-read-only (calculate-future-value (present-value uint) (annual-growth-rate uint) (years uint))
  ;; Use simple-pow but avoid calling calculate-future-value again
  (let (
    (growth-factor (+ u1000 annual-growth-rate))  ;; 5% = 1050
    (compound-factor (simple-pow growth-factor years))
  )
    (/ (* present-value compound-factor) (pow u10 (+ u3 (* u3 years))))
  )
)

(define-public (set-valuation (property-id uint) (method (string-utf8 20)) (timestamp uint) (value uint))
  (begin
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> value u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> (len method) u0) (err ERR_INVALID_PARAMETERS))
    
    (map-set property-valuations { property-id: property-id }
      { valuation-history: (list 10 (tuple (method method) (timestamp timestamp) (value value))) })
    (ok u"Valuation updated successfully")
  )
)

(define-public (update-owner (new-owner principal))
  (if (is-eq tx-sender contract-owner)
      (begin
        (var-set contract-owner new-owner)
        (ok new-owner)
      )
      (err u"Unauthorized")
  )
)

;; Modified format-amount function to use a simple approach
(define-public (format-amount (amount uint))
  (ok (to-uint amount))
)

;; Public variables
(define-data-var next-property-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Read-only functions

(define-read-only (get-property-details (property-id uint))
  (begin
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    (match (map-get? properties { property-id: property-id })
      property-data (ok property-data)
      (err ERR_PROPERTY_NOT_FOUND)
    )
  )
)

(define-read-only (get-property-valuation (property-id uint))
  (begin
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    (match (map-get? properties { property-id: property-id })
      property-data (ok (get last-valuation property-data))
      (err ERR_PROPERTY_NOT_FOUND)
    )
  )
)

(define-read-only (get-property-valuation-history (property-id uint))
  (begin
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    (match (map-get? property-valuations { property-id: property-id })
      valuation-data (ok (get valuation-history valuation-data))
      (err ERR_PROPERTY_NOT_FOUND)
    )
  )
)

;; Public functions

(define-public (register-property 
    (location-hash (buff 32)) 
    (square-footage uint) 
    (bedroom-count uint) 
    (bathroom-count uint) 
    (year-built uint)
    (initial-valuation uint))
  (let 
    (
      (property-id (var-get next-property-id))
      (current-time (get-block-info? time (- block-height u1)))
    )
    ;; Check parameters
    (asserts! (> square-footage u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> bedroom-count u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> bathroom-count u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> year-built u1900) (err ERR_INVALID_PARAMETERS))
    (asserts! (> initial-valuation u0) (err ERR_INVALID_PARAMETERS))
    
    ;; Register property
    (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        location-hash: location-hash,
        square-footage: square-footage,
        bedroom-count: bedroom-count,
        bathroom-count: bathroom-count,
        year-built: year-built,
        last-sale-price: u0,
        last-sale-timestamp: u0,
        last-valuation: initial-valuation,
        last-valuation-timestamp: (default-to u0 current-time)
      }
    )
    
    ;; Initialize valuation history
    (map-set property-valuations
      { property-id: property-id }
      {
        valuation-history: (list 
          (tuple
            (method "initial")
            (timestamp (default-to u0 current-time))
            (value initial-valuation)
          )
        )
      }
    )
    
    ;; Increment property ID counter
    (var-set next-property-id (+ property-id u1))
    
    (ok property-id)
  )
)

(define-public (update-property-valuation (property-id uint) (new-valuation uint) (method (string-utf8 20)))
  (let 
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) (err ERR_PROPERTY_NOT_FOUND)))
      (current-time (get-block-info? time (- block-height u1)))
      (valuation-data (unwrap! (map-get? property-valuations { property-id: property-id }) (err ERR_PROPERTY_NOT_FOUND)))
    )
    
    ;; Validate inputs
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> new-valuation u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> (len method) u0) (err ERR_INVALID_PARAMETERS))
    
    ;; Check ownership
    (asserts! (or (is-eq tx-sender (get owner property)) (is-eq tx-sender (var-get contract-owner))) (err ERR_UNAUTHORIZED))
    
    ;; Update property valuation
    (map-set properties
      { property-id: property-id }
      (merge property { 
        last-valuation: new-valuation,
        last-valuation-timestamp: (default-to u0 current-time)
      })
    )
    
    ;; Update valuation history
    (map-set property-valuations
      { property-id: property-id }
      {
        valuation-history: (unwrap-panic (as-max-len? 
          (append (get valuation-history valuation-data) 
            (tuple
              (method method)
              (timestamp (default-to u0 current-time))
              (value new-valuation)
            )
          )
          u10
        ))
      }
    )
    
    (ok true)
  )
)

(define-public (record-property-sale (property-id uint) (sale-price uint))
  (let 
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) (err ERR_PROPERTY_NOT_FOUND)))
      (current-time (get-block-info? time (- block-height u1)))
    )
    
    ;; Validate inputs
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (> sale-price u0) (err ERR_INVALID_PARAMETERS))
    
    ;; Check ownership
    (asserts! (is-eq tx-sender (get owner property)) (err ERR_UNAUTHORIZED))
    
    ;; Update property details
    (map-set properties
      { property-id: property-id }
      (merge property { 
        last-sale-price: sale-price,
        last-sale-timestamp: (default-to u0 current-time),
        last-valuation: sale-price,
        last-valuation-timestamp: (default-to u0 current-time)
      })
    )
    
    ;; Update valuation history
    (map-set property-valuations
      { property-id: property-id }
      {
        valuation-history: (unwrap-panic (as-max-len? 
          (append (get valuation-history (unwrap! (map-get? property-valuations { property-id: property-id }) (err ERR_PROPERTY_NOT_FOUND))) 
            (tuple
              (method "sale")
              (timestamp (default-to u0 current-time))
              (value sale-price)
            )
          )
          u10
        ))
      }
    )
    
    (ok true)
  )
)

(define-public (transfer-property (property-id uint) (new-owner principal))
  (let 
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) (err ERR_PROPERTY_NOT_FOUND)))
    )
    
    ;; Validate inputs
    (asserts! (> property-id u0) (err ERR_INVALID_PARAMETERS))
    
    ;; Check ownership
    (asserts! (is-eq tx-sender (get owner property)) (err ERR_UNAUTHORIZED))
    
    ;; Transfer property
    (map-set properties
      { property-id: property-id }
      (merge property { owner: new-owner })
    )
    
    (ok true)
  )
)

;; Contract owner functions

(define-public (update-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)

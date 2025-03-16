;; Valuation Engine Contract
;; This contract calculates property valuations based on various factors and algorithms

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_PROPERTY_NOT_FOUND (err u301))
(define-constant ERR_INVALID_PARAMETERS (err u302))
(define-constant ERR_CALCULATION_FAILED (err u303))

;; Data maps
(define-map market-factors
  { zip-code: (string-utf8 10) }
  {
    price-per-sqft: uint,
    growth-rate: uint,  ;; Basis points (1/100 of a percent)
    last-updated: uint
  }
)

(define-map property-comparables
  { property-id: uint }
  {
    comparable-properties: (list 5 uint),
    last-updated: uint
  }
)

(define-map valuation-weights
  { method-name: (string-utf8 20) }
  {
    weight: uint,  ;; Basis points (1/100 of a percent)
    enabled: bool
  }
)

;; Public variables
(define-data-var contract-owner principal tx-sender)

;; Read-only functions

(define-read-only (get-market-factors (zip-code (string-utf8 10)))
  (match (map-get? market-factors { zip-code: zip-code })
    factors (ok factors)
    (err ERR_PROPERTY_NOT_FOUND)
  )
)

(define-read-only (get-property-comparables (property-id uint))
  (match (map-get? property-comparables { property-id: property-id })
    comparables (ok comparables)
    (err ERR_PROPERTY_NOT_FOUND)
  )
)

(define-read-only (get-valuation-weight (method-name (string-utf8 20)))
  (match (map-get? valuation-weights { method-name: method-name })
    weight-data (ok weight-data)
    (err ERR_PROPERTY_NOT_FOUND)
  )
)

(define-read-only (calculate-base-valuation (property-id uint))
  (begin
    ;; Basic valuation calculation (simplified for initial implementation)
    ;; This would typically use property data from the main contract
    ;; For now, we'll use a simple formula based just on the property ID
    (ok (* property-id u100000))
  )
)

(define-read-only (calculate-market-adjusted-valuation (property-id uint) (zip-code (string-utf8 10)))
  (let 
    (
      (base-valuation-result (calculate-base-valuation property-id))
      (base-valuation (unwrap! base-valuation-result (err ERR_CALCULATION_FAILED)))
      (market-factors-result (get-market-factors zip-code))
      (market-data (unwrap! market-factors-result (err ERR_PROPERTY_NOT_FOUND)))
      (price-per-sqft (get price-per-sqft market-data))
      (growth-rate (get growth-rate market-data))
    )
    ;; Market adjusted valuation - using a simple multiplier for now
    (ok (+ base-valuation (* base-valuation (/ growth-rate u10000))))
  )
)

;; Public functions

(define-public (set-market-factors 
    (zip-code (string-utf8 10)) 
    (price-per-sqft uint) 
    (growth-rate uint))
  (begin
    ;; Only contract owner can set market factors
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    
    ;; Validate parameters
    (asserts! (> price-per-sqft u0) (err ERR_INVALID_PARAMETERS))
    (asserts! (<= growth-rate u5000) (err ERR_INVALID_PARAMETERS))  ;; Max 50% growth rate
    
    ;; Set market factors
    (map-set market-factors
      { zip-code: zip-code }
      {
        price-per-sqft: price-per-sqft,
        growth-rate: growth-rate,
        last-updated: (default-to u0 (get-block-info? time (- block-height u1)))
      }
    )
    
    (ok true)
  )
)

(define-public (set-property-comparables 
    (property-id uint) 
    (comparable-properties (list 5 uint)))
  (begin
    ;; Set property comparables
    (map-set property-comparables
      { property-id: property-id }
      {
        comparable-properties: comparable-properties,
        last-updated: (default-to u0 (get-block-info? time (- block-height u1)))
      }
    )
    
    (ok true)
  )
)

(define-public (set-valuation-weight 
    (method-name (string-utf8 20)) 
    (weight uint) 
    (enabled bool))
  (begin
    ;; Only contract owner can set valuation weights
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    
    ;; Validate parameters
    (asserts! (<= weight u10000) (err ERR_INVALID_PARAMETERS))  ;; Max 100% weight
    
    ;; Set valuation weight
    (map-set valuation-weights
      { method-name: method-name }
      {
        weight: weight,
        enabled: enabled
      }
    )
    
    (ok true)
  )
)

(define-public (calculate-and-update-valuation (property-id uint) (zip-code (string-utf8 10)))
  (let 
    (
      (market-adjusted-result (calculate-market-adjusted-valuation property-id zip-code))
      (market-adjusted-value (unwrap! market-adjusted-result (err ERR_CALCULATION_FAILED)))
    )
    ;; Return the calculated value - in production this would update the main contract
    (ok market-adjusted-value)
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

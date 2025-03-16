;; Property Registry Contract
;; This contract manages the registration and ownership details of properties

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_PROPERTY_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PARAMETERS (err u202))

;; Data maps
(define-map property-metadata
  { property-id: uint }
  {
    address: (string-utf8 256),
    coordinates: (tuple (latitude (string-utf8 20)) (longitude (string-utf8 20))),
    property-type: (string-utf8 20),
    zone-classification: (string-utf8 50),
    taxable-value: uint,
    last-assessment-date: uint,
    additional-details: (string-utf8 500)
  }
)

(define-map property-features
  { property-id: uint }
  {
    has-garage: bool,
    has-pool: bool,
    has-basement: bool,
    has-solar-panels: bool,
    has-renovations: bool,
    renovation-year: uint,
    lot-size: uint,
    floor-count: uint,
    parking-spaces: uint,
    features-list: (list 20 (string-utf8 30))
  }
)

;; Read-only functions

(define-read-only (get-property-metadata (property-id uint))
  (match (map-get? property-metadata { property-id: property-id })
    metadata (ok metadata)
    (err ERR_PROPERTY_NOT_FOUND)
  )
)

(define-read-only (get-property-features (property-id uint))
  (match (map-get? property-features { property-id: property-id })
    features (ok features)
    (err ERR_PROPERTY_NOT_FOUND)
  )
)

;; Public functions

(define-public (register-property-metadata 
    (property-id uint)
    (address (string-utf8 256))
    (latitude (string-utf8 20))
    (longitude (string-utf8 20))
    (property-type (string-utf8 20))
    (zone-classification (string-utf8 50))
    (taxable-value uint)
    (last-assessment-date uint)
    (additional-details (string-utf8 500)))
  (begin
    ;; Set property metadata
    (map-set property-metadata
      { property-id: property-id }
      {
        address: address,
        coordinates: { latitude: latitude, longitude: longitude },
        property-type: property-type,
        zone-classification: zone-classification,
        taxable-value: taxable-value,
        last-assessment-date: last-assessment-date,
        additional-details: additional-details
      }
    )
    
    (ok true)
  )
)

(define-public (register-property-features
    (property-id uint)
    (has-garage bool)
    (has-pool bool)
    (has-basement bool)
    (has-solar-panels bool)
    (has-renovations bool)
    (renovation-year uint)
    (lot-size uint)
    (floor-count uint)
    (parking-spaces uint)
    (features-list (list 20 (string-utf8 30))))
  (begin
    ;; Set property features
    (map-set property-features
      { property-id: property-id }
      {
        has-garage: has-garage,
        has-pool: has-pool,
        has-basement: has-basement,
        has-solar-panels: has-solar-panels,
        has-renovations: has-renovations,
        renovation-year: renovation-year,
        lot-size: lot-size,
        floor-count: floor-count,
        parking-spaces: parking-spaces,
        features-list: features-list
      }
    )
    
    (ok true)
  )
)

(define-public (update-property-metadata
    (property-id uint)
    (address (optional (string-utf8 256)))
    (latitude (optional (string-utf8 20)))
    (longitude (optional (string-utf8 20)))
    (property-type (optional (string-utf8 20)))
    (zone-classification (optional (string-utf8 50)))
    (taxable-value (optional uint))
    (last-assessment-date (optional uint))
    (additional-details (optional (string-utf8 500))))
  (let
    (
      (existing-metadata (unwrap! (map-get? property-metadata { property-id: property-id }) (err ERR_PROPERTY_NOT_FOUND)))
    )
    ;; Update property metadata
    (map-set property-metadata
      { property-id: property-id }
      {
        address: (default-to (get address existing-metadata) address),
        coordinates: {
          latitude: (default-to (get latitude (get coordinates existing-metadata)) latitude),
          longitude: (default-to (get longitude (get coordinates existing-metadata)) longitude)
        },
        property-type: (default-to (get property-type existing-metadata) property-type),
        zone-classification: (default-to (get zone-classification existing-metadata) zone-classification),
        taxable-value: (default-to (get taxable-value existing-metadata) taxable-value),
        last-assessment-date: (default-to (get last-assessment-date existing-metadata) last-assessment-date),
        additional-details: (default-to (get additional-details existing-metadata) additional-details)
      }
    )
    
    (ok true)
  )
)

;; Utils Contract
;; This contract provides utility functions for the real estate valuation system

;; Constants
(define-constant PRECISION u1000000)  ;; 6 decimal places of precision
(define-constant SECONDS_PER_YEAR u31536000)  ;; 365 days * 24 hours * 60 minutes * 60 seconds

;; Basic utility functions without dependencies
(define-read-only (calculate-percentage (value uint) (total uint))
  (if (> total u0)
      (/ (* value u10000) total)  
      u0)
)

(define-read-only (average-of-list (values (list 20 uint)))
  (let
    (
      (sum (fold + values u0))
      (count (len values))
    )
    (if (> count u0)
        (/ sum count)
        u0)
  )
)

(define-read-only (hash-string (input (string-utf8 256)))
  (sha256 (unwrap-panic (as-max-len? input u256)))
)

(define-read-only (calculate-depreciation (property-value uint) (age-years uint) (depreciation-rate uint))
  (let
    (
      (total-depreciation (/ (* property-value depreciation-rate age-years) u10000))
    )
    ;; Ensure we don't depreciate more than the property value
    (if (> total-depreciation property-value)
        u0
        (- property-value total-depreciation))
  )
)

(define-read-only (calculate-annual-growth (initial-value uint) (final-value uint) (time-elapsed-seconds uint))
  (let
    (
      (value-change (if (>= final-value initial-value)
                        (- final-value initial-value)
                        u0))
      (years-elapsed (if (> time-elapsed-seconds u0)
                         (/ (* time-elapsed-seconds PRECISION) SECONDS_PER_YEAR)
                         PRECISION))
    )
    (if (and (> initial-value u0) (> years-elapsed u0))
        (/ (* value-change u10000) (* initial-value (/ years-elapsed PRECISION)))
        u0)
  )
)

;; Simple median implementation
(define-read-only (median-of-list (values (list 20 uint)))
  (let
    (
      (count (len values))
    )
    (if (<= count u0)
        u0
        (if (is-eq count u1)
            (default-to u0 (element-at values u0))
            (/ (+ (default-to u0 (element-at values u0)) 
                  (default-to u0 (element-at values (- count u1))))
               u2))
    )
  )
)

;; Instead of the interdependent string conversion, use a simpler approach
(define-read-only (format-currency (amount uint))
  (concat u"" amount u" STX")
)

;; Exponential function without using list-repeat
(define-read-only (simple-pow (base uint) (exponent uint))
  (if (is-eq exponent u0)
      u1
      (if (is-eq exponent u1)
          base
          (* base (simple-pow base (- exponent u1)))))
)

;; Calculate future value using compound interest formula
(define-read-only (calculate-future-value (present-value uint) (growth-rate uint) (years uint))
  ;; growth-rate is in basis points (1/100 of a percent)
  ;; Formula: FV = PV * (1 + r)^n where r is growth-rate/10000
  (let
    (
      (growth-factor (+ PRECISION (/ (* growth-rate PRECISION) u10000)))
      (multiplier (simple-pow growth-factor years))
    )
    (if (is-eq years u0)
        present-value
        (/ (* present-value multiplier) PRECISION))
  )
)

;; Machine Learning Project Smart Contract
;; A decentralized platform for ML model registry, dataset management, and predictions
;; Version: 1.0.0
;; Compatible with: Clarinet 3.x

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_MODEL_NOT_FOUND (err u404))
(define-constant ERR_DATASET_NOT_FOUND (err u405))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u402))
(define-constant ERR_INVALID_PARAMETERS (err u400))
(define-constant ERR_MODEL_ALREADY_EXISTS (err u409))
(define-constant ERR_PREDICTION_NOT_FOUND (err u406))

;; Data Variables
(define-data-var model-counter uint u0)
(define-data-var dataset-counter uint u0)
(define-data-var prediction-counter uint u0)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Data Maps
(define-map models 
    { model-id: uint }
    {
        owner: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        model-type: (string-ascii 32),
        accuracy: uint,
        price-per-prediction: uint,
        total-predictions: uint,
        created-at: uint,
        is-active: bool
    }
)

(define-map datasets 
    { dataset-id: uint }
    {
        owner: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        size: uint,
        features: uint,
        price: uint,
        created-at: uint,
        is-public: bool
    }
)

(define-map predictions 
    { prediction-id: uint }
    {
        requester: principal,
        model-id: uint,
        input-hash: (buff 32),
        result: (optional (string-ascii 128)),
        confidence: (optional uint),
        paid-amount: uint,
        created-at: uint,
        completed: bool
    }
)

(define-map model-ratings
    { model-id: uint, rater: principal }
    { rating: uint, timestamp: uint }
)

;; Public Functions

;; Register a new ML model
(define-public (register-model 
    (name (string-ascii 64))
    (description (string-ascii 256))
    (model-type (string-ascii 32))
    (accuracy uint)
    (price-per-prediction uint))
    (let 
        (
            (new-model-id (+ (var-get model-counter) u1))
        )
        (asserts! (> (len name) u0) ERR_INVALID_PARAMETERS)
        (asserts! (and (>= accuracy u0) (<= accuracy u100)) ERR_INVALID_PARAMETERS)
        (asserts! (> price-per-prediction u0) ERR_INVALID_PARAMETERS)
        
        (map-set models { model-id: new-model-id }
            {
                owner: tx-sender,
                name: name,
                description: description,
                model-type: model-type,
                accuracy: accuracy,
                price-per-prediction: price-per-prediction,
                total-predictions: u0,
                created-at: burn-block-height,
                is-active: true
            }
        )
        (var-set model-counter new-model-id)
        (ok new-model-id)
    )
)

;; Register a new dataset
(define-public (register-dataset
    (name (string-ascii 64))
    (description (string-ascii 256))
    (size uint)
    (features uint)
    (price uint)
    (is-public bool))
    (let 
        (
            (new-dataset-id (+ (var-get dataset-counter) u1))
        )
        (asserts! (> (len name) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> size u0) ERR_INVALID_PARAMETERS)
        (asserts! (> features u0) ERR_INVALID_PARAMETERS)
        
        (map-set datasets { dataset-id: new-dataset-id }
            {
                owner: tx-sender,
                name: name,
                description: description,
                size: size,
                features: features,
                price: price,
                created-at: burn-block-height,
                is-public: is-public
            }
        )
        (var-set dataset-counter new-dataset-id)
        (ok new-dataset-id)
    )
)

;; Request a prediction from a model
(define-public (request-prediction 
    (model-id uint)
    (input-hash (buff 32)))
    (let 
        (
            (model (unwrap! (map-get? models { model-id: model-id }) ERR_MODEL_NOT_FOUND))
            (prediction-price (get price-per-prediction model))
            (new-prediction-id (+ (var-get prediction-counter) u1))
        )
        (asserts! (get is-active model) ERR_MODEL_NOT_FOUND)
        (asserts! (>= (stx-get-balance tx-sender) prediction-price) ERR_INSUFFICIENT_PAYMENT)
        
        ;; Transfer payment to contract
        (try! (stx-transfer? prediction-price tx-sender (as-contract tx-sender)))
        
        (map-set predictions { prediction-id: new-prediction-id }
            {
                requester: tx-sender,
                model-id: model-id,
                input-hash: input-hash,
                result: none,
                confidence: none,
                paid-amount: prediction-price,
                created-at: burn-block-height,
                completed: false
            }
        )
        (var-set prediction-counter new-prediction-id)
        (ok new-prediction-id)
    )
)

;; Submit prediction result (only model owner)
(define-public (submit-prediction-result
    (prediction-id uint)
    (result (string-ascii 128))
    (confidence uint))
    (let 
        (
            (prediction (unwrap! (map-get? predictions { prediction-id: prediction-id }) ERR_PREDICTION_NOT_FOUND))
            (model (unwrap! (map-get? models { model-id: (get model-id prediction) }) ERR_MODEL_NOT_FOUND))
            (model-owner (get owner model))
            (payment (get paid-amount prediction))
            (platform-fee (/ (* payment (var-get platform-fee-percentage)) u100))
            (model-owner-payment (- payment platform-fee))
        )
        (asserts! (is-eq tx-sender model-owner) ERR_UNAUTHORIZED)
        (asserts! (not (get completed prediction)) ERR_INVALID_PARAMETERS)
        (asserts! (<= confidence u100) ERR_INVALID_PARAMETERS)
        
        ;; Update prediction
        (map-set predictions { prediction-id: prediction-id }
            (merge prediction {
                result: (some result),
                confidence: (some confidence),
                completed: true
            })
        )
        
        ;; Update model stats
        (map-set models { model-id: (get model-id prediction) }
            (merge model {
                total-predictions: (+ (get total-predictions model) u1)
            })
        )
        
        ;; Pay model owner
        (try! (as-contract (stx-transfer? model-owner-payment tx-sender model-owner)))
        
        (ok true)
    )
)

;; Rate a model
(define-public (rate-model 
    (model-id uint)
    (rating uint))
    (begin
        (asserts! (is-some (map-get? models { model-id: model-id })) ERR_MODEL_NOT_FOUND)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_PARAMETERS)
        
        (map-set model-ratings 
            { model-id: model-id, rater: tx-sender }
            { rating: rating, timestamp: burn-block-height }
        )
        (ok true)
    )
)

;; Update model status (only model owner)
(define-public (toggle-model-status (model-id uint))
    (let 
        (
            (model (unwrap! (map-get? models { model-id: model-id }) ERR_MODEL_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender (get owner model)) ERR_UNAUTHORIZED)
        
        (map-set models { model-id: model-id }
            (merge model { is-active: (not (get is-active model)) })
        )
        (ok true)
    )
)

;; Purchase dataset access
(define-public (purchase-dataset-access (dataset-id uint))
    (let 
        (
            (dataset (unwrap! (map-get? datasets { dataset-id: dataset-id }) ERR_DATASET_NOT_FOUND))
            (dataset-price (get price dataset))
            (dataset-owner (get owner dataset))
            (platform-fee (/ (* dataset-price (var-get platform-fee-percentage)) u100))
            (owner-payment (- dataset-price platform-fee))
        )
        (asserts! (not (get is-public dataset)) ERR_INVALID_PARAMETERS)
        (asserts! (>= (stx-get-balance tx-sender) dataset-price) ERR_INSUFFICIENT_PAYMENT)
        
        ;; Transfer payment
        (try! (stx-transfer? owner-payment tx-sender dataset-owner))
        (try! (stx-transfer? platform-fee tx-sender CONTRACT_OWNER))
        
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-model (model-id uint))
    (map-get? models { model-id: model-id })
)

(define-read-only (get-dataset (dataset-id uint))
    (map-get? datasets { dataset-id: dataset-id })
)

(define-read-only (get-prediction (prediction-id uint))
    (map-get? predictions { prediction-id: prediction-id })
)

(define-read-only (get-model-rating (model-id uint) (rater principal))
    (map-get? model-ratings { model-id: model-id, rater: rater })
)

(define-read-only (get-model-counter)
    (var-get model-counter)
)

(define-read-only (get-dataset-counter)
    (var-get dataset-counter)
)

(define-read-only (get-prediction-counter)
    (var-get prediction-counter)
)

(define-read-only (get-platform-fee-percentage)
    (var-get platform-fee-percentage)
)

;; Admin functions (only contract owner)
(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (<= new-fee u20) ERR_INVALID_PARAMETERS) ;; Max 20% fee
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

;; Withdraw platform fees (only contract owner)
(define-public (withdraw-fees (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (<= amount (stx-get-balance (as-contract tx-sender))) ERR_INSUFFICIENT_PAYMENT)
        (try! (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER)))
        (ok true)
    )
)
# Machine Learning Project Smart Contract

A decentralized platform for machine learning model registry, dataset management, and prediction marketplace built on the Stacks blockchain using Clarity smart contracts.

## 🌟 Overview

This smart contract creates a decentralized ecosystem where:
- Data scientists can register and monetize their ML models
- Dataset owners can share and sell their datasets
- Users can request predictions from registered models
- A rating system ensures model quality and trust
- Platform fees support sustainable development

## 🏗️ Architecture

### Core Components

1. **Model Registry**: Register, manage, and monetize ML models
2. **Dataset Marketplace**: Share public datasets or sell private ones
3. **Prediction Service**: Request and fulfill ML predictions
4. **Rating System**: Community-driven model quality assessment
5. **Payment System**: STX-based payments with platform fees

### Data Structures

#### Models
- `model-id`: Unique identifier
- `owner`: Model creator's principal
- `name`: Human-readable model name (max 64 chars)
- `description`: Detailed description (max 256 chars)
- `model-type`: Classification/regression/etc (max 32 chars)
- `accuracy`: Model accuracy percentage (0-100)
- `price-per-prediction`: Cost in microSTX per prediction
- `total-predictions`: Number of completed predictions
- `created-at`: Block height of registration
- `is-active`: Whether model accepts new predictions

#### Datasets
- `dataset-id`: Unique identifier
- `owner`: Dataset owner's principal
- `name`: Dataset name (max 64 chars)
- `description`: Dataset description (max 256 chars)
- `size`: Number of samples
- `features`: Number of features/columns
- `price`: Cost in microSTX for access
- `created-at`: Block height of registration
- `is-public`: Whether dataset is freely accessible

#### Predictions
- `prediction-id`: Unique identifier
- `requester`: User who requested prediction
- `model-id`: Target model for prediction
- `input-hash`: Hash of input data (32 bytes)
- `result`: Prediction result (max 128 chars)
- `confidence`: Prediction confidence (0-100)
- `paid-amount`: Amount paid for prediction
- `created-at`: Block height of request
- `completed`: Whether prediction is fulfilled

## 🚀 Getting Started

### Prerequisites

- [Clarinet 3.x](https://github.com/hirosystems/clarinet)
- [Stacks CLI](https://docs.stacks.co/docs/command-line-interface)
- Node.js (for testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd machine-learning-project
   ```

2. **Initialize Clarinet project** (if not already done)
   ```bash
   clarinet new machine-learning-project
   cd machine-learning-project
   ```

3. **Add the contract**
   ```bash
   clarinet contract new ml-project
   ```

4. **Copy the contract code**
   Copy the contents of `ml-project.cty` to `contracts/ml-project.cty`

5. **Update Clarinet.toml**
   ```toml
   [contracts.ml-project]
   path = "contracts/ml-project.cty"
   ```

### Testing

Run the contract tests:
```bash
clarinet test
```

Start the development environment:
```bash
clarinet integrate
```

## 📖 Usage Guide

### For Model Owners

#### 1. Register a Model
```clarity
(contract-call? .ml-project register-model 
  "Image Classifier" 
  "CNN model for image classification with 95% accuracy"
  "classification"
  u95
  u1000)  ;; 1000 microSTX per prediction
```

#### 2. Submit Prediction Results
```clarity
(contract-call? .ml-project submit-prediction-result
  u1    ;; prediction-id
  "cat"  ;; prediction result
  u92)   ;; confidence percentage
```

#### 3. Toggle Model Availability
```clarity
(contract-call? .ml-project toggle-model-status u1)
```

### For Dataset Owners

#### Register a Dataset
```clarity
(contract-call? .ml-project register-dataset
  "ImageNet Subset"
  "10K labeled images for training classification models"
  u10000  ;; size (samples)
  u2048   ;; features (dimensions)
  u50000  ;; price in microSTX
  false)  ;; not public (requires payment)
```

### For Users

#### 1. Request a Prediction
```clarity
(contract-call? .ml-project request-prediction
  u1  ;; model-id
  0x1234567890abcdef1234567890abcdef12345678)  ;; input hash
```

#### 2. Purchase Dataset Access
```clarity
(contract-call? .ml-project purchase-dataset-access u1)
```

#### 3. Rate a Model
```clarity
(contract-call? .ml-project rate-model u1 u5)  ;; 5-star rating
```

### Query Functions

#### Get Model Information
```clarity
(contract-call? .ml-project get-model u1)
```

#### Get Prediction Status
```clarity
(contract-call? .ml-project get-prediction u1)
```

#### Get Dataset Details
```clarity
(contract-call? .ml-project get-dataset u1)
```

## 💰 Economics

### Platform Fees
- Default: 5% of all transactions
- Adjustable by contract owner (max 20%)
- Applied to predictions and dataset purchases

### Payment Flow
1. **Predictions**: User pays → Contract holds → Model owner receives (95%) → Platform keeps (5%)
2. **Datasets**: Buyer pays → Dataset owner receives (95%) → Platform keeps (5%)

### Fee Structure
- Prediction requests: Pay upfront, settled upon completion
- Dataset access: Immediate payment split
- Model registration: Free
- Dataset registration: Free

## 🔧 Development

### Contract Functions

#### Public Functions
- `register-model`: Register a new ML model
- `register-dataset`: Register a new dataset
- `request-prediction`: Request prediction from a model
- `submit-prediction-result`: Submit prediction results (model owners only)
- `rate-model`: Rate a model (1-5 stars)
- `toggle-model-status`: Activate/deactivate model
- `purchase-dataset-access`: Buy access to private dataset
- `update-platform-fee`: Update platform fee (admin only)
- `withdraw-fees`: Withdraw collected fees (admin only)

#### Read-Only Functions
- `get-model`: Retrieve model information
- `get-dataset`: Retrieve dataset information
- `get-prediction`: Retrieve prediction information
- `get-model-rating`: Get specific rating for model
- `get-model-counter`: Get total number of models
- `get-dataset-counter`: Get total number of datasets
- `get-prediction-counter`: Get total number of predictions
- `get-platform-fee-percentage`: Get current platform fee

### Error Codes
- `u400`: Invalid parameters
- `u401`: Unauthorized access
- `u402`: Insufficient payment
- `u404`: Model not found
- `u405`: Dataset not found
- `u406`: Prediction not found
- `u409`: Model already exists

## 🧪 Testing Scenarios

### Basic Flow Test
1. Deploy contract
2. Register a model
3. Request a prediction
4. Submit prediction result
5. Verify payment distribution

### Edge Cases
- Invalid accuracy values (>100 or <0)
- Insufficient balance for predictions
- Unauthorized prediction submissions
- Rating out of range (not 1-5)

## 🔐 Security Considerations

### Access Control
- Model owners can only submit results for their models
- Only contract owner can adjust fees and withdraw
- Users can only rate models, not manipulate core data

### Payment Security
- Payments held in contract until prediction completion
- Platform fees automatically calculated and distributed
- No direct token transfers between users

### Data Privacy
- Input data stored as hash only
- Prediction results are public once submitted
- No sensitive ML model data stored on-chain

## 🚧 Future Enhancements

### Planned Features
- Model versioning system
- Batch prediction requests
- Staking mechanisms for model quality
- Governance token for platform decisions
- Integration with IPFS for large datasets

### Potential Improvements
- Gas optimization for large-scale usage
- Cross-chain compatibility
- Advanced rating algorithms
- Model performance tracking
- Automated testing frameworks

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Documentation**: Check the [Stacks documentation](https://docs.stacks.co)

## 🙏 Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarinet team for development tools
- The broader Stacks developer community

---

**Built with ❤️ for the decentralized AI future**

# machine-learning-project


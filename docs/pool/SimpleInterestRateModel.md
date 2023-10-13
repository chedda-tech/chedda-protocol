# Solidity API

## SimpleInterestRateModel

### linearInterestRate

```solidity
uint256 linearInterestRate
```

### exponentialInterestRate

```solidity
uint256 exponentialInterestRate
```

### targetUtilization

```solidity
uint256 targetUtilization
```

### constructor

```solidity
constructor(uint256 _linearRate, uint256 _exponentialRate, uint256 _targetUtilization) public
```

### calculateInterestRate

```solidity
function calculateInterestRate(uint256 currentUtilization) public view returns (uint256)
```

### updateLinearInterestRate

```solidity
function updateLinearInterestRate(uint256 newLinearRate) public
```

### updateExponentialInterestRate

```solidity
function updateExponentialInterestRate(uint256 newExponentialRate) public
```

### updateTargetUtilization

```solidity
function updateTargetUtilization(uint256 newTargetUtilization) public
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256, uint256) external pure returns (struct InterestRates)
```


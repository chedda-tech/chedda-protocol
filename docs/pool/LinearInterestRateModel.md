# Solidity API

## LinearInterestRateModel

### owner

```solidity
address owner
```

### baseInterestRate

```solidity
uint256 baseInterestRate
```

### steeperSlopeInterestRate

```solidity
uint256 steeperSlopeInterestRate
```

### targetUtilization

```solidity
uint256 targetUtilization
```

### constructor

```solidity
constructor(uint256 _baseInterestRate, uint256 _steeperSlopeInterestRate, uint256 _targetUtilization) public
```

### calculateInterestRate

```solidity
function calculateInterestRate(uint256 utilization) public view returns (uint256)
```

### updateInterestRateParameters

```solidity
function updateInterestRateParameters(uint256 _baseInterestRate, uint256 _steeperSlopeInterestRate, uint256 _targetUtilization) public
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256, uint256) external pure returns (struct InterestRates)
```


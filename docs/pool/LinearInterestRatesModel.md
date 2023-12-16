# Solidity API

## LinearInterestRatesModel

### owner

```solidity
address owner
```

### baseSupplyRate

```solidity
uint256 baseSupplyRate
```

### baseBorrowRate

```solidity
uint256 baseBorrowRate
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
constructor(uint256 _baseSupplyRate, uint256 _baseBorrowRate, uint256 _steeperSlopeInterestRate, uint256 _targetUtilization) public
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256 utilization) public view returns (struct InterestRates)
```


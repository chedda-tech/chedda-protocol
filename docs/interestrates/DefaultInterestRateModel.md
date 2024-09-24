# Solidity API

## DefaultInterestRateModel

### baseBorrowRate

```solidity
uint256 baseBorrowRate
```

### rateSlope1

```solidity
uint256 rateSlope1
```

### rateSlope2

```solidity
uint256 rateSlope2
```

### targetUtilization

```solidity
uint256 targetUtilization
```

### reserveFactor

```solidity
uint256 reserveFactor
```

### constructor

```solidity
constructor(uint256 _baseBorrowRate, uint256 _rateSlope1, uint256 _rateSlope2, uint256 _targetUtilization, uint256 _reserveFactor) public
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256 utilization) public view returns (struct InterestRates)
```


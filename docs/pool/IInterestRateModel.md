# Solidity API

## InterestRates

```solidity
struct InterestRates {
  uint256 supplyRate;
  uint256 borrowRate;
}
```

## IInterestRateModel

### calculateInterestRate

```solidity
function calculateInterestRate(uint256 utilization) external view returns (uint256)
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256 liquidityAdded, uint256 liquidityTaken) external view returns (struct InterestRates)
```


# Solidity API

## InterestRates

```solidity
struct InterestRates {
  uint256 utilization;
  uint256 supplyRate;
  uint256 borrowRate;
}
```

## IInterestRatesModel

### calculateInterestRates

```solidity
function calculateInterestRates(uint256 utilization) external view returns (struct InterestRates)
```


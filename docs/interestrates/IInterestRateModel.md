# Solidity API

## InterestRates

Explain to an end user what this does

_Explain to a developer any extra details_

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct InterestRates {
  uint256 utilization;
  uint256 supplyRate;
  uint256 effectiveSupplyRate;
  uint256 borrowRate;
}
```

## IInterestRateModel

_Interface representing interest rate model_

### calculateInterestRates

```solidity
function calculateInterestRates(uint256 utilization) external view returns (struct InterestRates)
```


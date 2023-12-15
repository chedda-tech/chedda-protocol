# Solidity API

## InterestRatesProjector

Allows you to view the interest rates at various utilizations

### projection

```solidity
function projection(address interestRatesModel, uint256[] utilizations) external view returns (struct InterestRates[])
```

Returns the interest rates at various utilizations

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interestRatesModel | address | The interest rate model |
| utilizations | uint256[] | An array of utilizations to return interest rates for. 1e18 = 100% utilization. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct InterestRates[] | interestRates An array of interest rates corresponding to utilizations passed in. |


# Solidity API

## IDIAOracleV2

_DIA oracle interface_

### getValue

```solidity
function getValue(string key) external view returns (uint128 lastPrice, uint128 lastUpdated)
```

Returns the price and last update time of a given price feed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| key | string | The key to get price for. e.g BTCUSD |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| lastPrice | uint128 | last price reported |
| lastUpdated | uint128 | Timestamp of last update |


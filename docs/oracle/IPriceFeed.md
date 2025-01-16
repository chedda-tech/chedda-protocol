# Solidity API

## IPriceFeed

### decimals

```solidity
function decimals() external view returns (uint8)
```

_The decimals of values returned by this feed._

### readPrice

```solidity
function readPrice(address token) external view returns (int256 price, uint256 lastUpdated)
```

Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
tokenID parameter is for forwards compatibility.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | address of the asset's token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | int256 | the price of the asset |
| lastUpdated | uint256 |  |


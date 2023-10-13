# Solidity API

## IPriceFeed

### token

```solidity
function token() external view returns (address)
```

The token this feed returns a price for.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address token addrss. |

### readPrice

```solidity
function readPrice(address token, uint256 tokenID) external view returns (int256 price)
```

Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
tokenID parameter is for forwards compatibility.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | address of the asset's token. |
| tokenID | uint256 | The number of tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | int256 | the price of the asset |


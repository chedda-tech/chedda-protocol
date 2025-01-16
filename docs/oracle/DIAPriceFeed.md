# Solidity API

## DIAPriceFeed

Represents an instance of a feed that reads values from a DIA oracle.

### oracle

```solidity
address oracle
```

_oracle address_

### decimals

```solidity
uint8 decimals
```

_number of decimals for values returned by this feed._

### feedKeyMap

```solidity
mapping(address => string) feedKeyMap
```

_mapping from token address to key used to fetch prices from DIA oracle._

### FeedKeyMap

Explain to an end user what this does

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct FeedKeyMap {
  string key;
  address tokenAddress;
}
```

### constructor

```solidity
constructor(address _oracle, uint8 _decimals, struct DIAPriceFeed.FeedKeyMap[] _initFeedMap) public
```

Constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _oracle | address | The oracle address. |
| _decimals | uint8 | The number of decimals for values returned from `readPrice`. |
| _initFeedMap | struct DIAPriceFeed.FeedKeyMap[] | A map of token address to feed key. |

### readPrice

```solidity
function readPrice(address token) external view returns (int256 price, uint256 lastUpdated)
```

Get latest price of asset.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | address of the asset's token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | int256 | the price of the asset |
| lastUpdated | uint256 |  |


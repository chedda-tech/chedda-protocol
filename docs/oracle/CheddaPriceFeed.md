# Solidity API

## CheddaPriceFeed

### ZeroAddress

```solidity
error ZeroAddress()
```

### decimals

```solidity
uint8 decimals
```

_The decimals of values returned by this feed._

### constructor

```solidity
constructor(uint8 _decimals) public
```

### setPrice

```solidity
function setPrice(address _token, int256 _price) public
```

Sets the priceed feed for a token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | address | The token address |
| _price | int256 | The price of token |

### readPrice

```solidity
function readPrice(address _token, uint256) public view returns (int256 price)
```

_Explain to a developer any extra details_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | int256 | the latest price |

### token

```solidity
function token() external pure returns (address)
```

The token this feed returns a price for.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address token addrss. |


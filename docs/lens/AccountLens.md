# Solidity API

## AccountLens

Provides views into accounts and positions.

### Position

```solidity
struct Position {
  address account;
  address pool;
  address asset;
  uint8 decimals;
  uint256 supplied;
  uint256 borrowed;
  uint256 debtValue;
  uint256 collateralValue;
  uint256 healthFactor;
}
```

### registry

```solidity
contract IAddressRegistry registry
```

### constructor

```solidity
constructor(address _registry) public
```

### allPositions

```solidity
function allPositions(address account, bool showActiveOnly) external view returns (struct AccountLens.Position[])
```

Returns an array containing tha accounts positions.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check |
| showActiveOnly | bool | If true only return positions in active pools,  else return positions in all registered pools. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AccountLens.Position[] | Array of accounts positions |

### getPosition

```solidity
function getPosition(address account, address poolAddress) public view returns (struct AccountLens.Position)
```

Gets an account position in a lending pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to retrive the position for |
| poolAddress | address | The pool address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AccountLens.Position | The `Position` holding the values for the account position.  If `account` does not have a position in this pool the numerical values are all zero. |


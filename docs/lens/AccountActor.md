# Solidity API

## AccountActor

Provides views into accounts and positions.

### ZeroAddress

```solidity
error ZeroAddress()
```

_Reverts if zero addrss provided_

### AccountSummary

```solidity
struct AccountSummary {
  uint256 netValue;
  uint256 suppliedValue;
  uint256 borrowedValue;
  uint256 lockedValue;
}
```

### Position

Contains info about a position.

```solidity
struct Position {
  address account;
  address pool;
  address asset;
  uint8 decimals;
  uint256 supplied;
  uint256 borrowed;
  uint256 suppliedValue;
  uint256 borrowedValue;
  uint256 collateralValue;
  uint256 healthFactor;
  uint256 staked;
  uint256 locked;
  uint256 stakeRewardsClaimable;
  uint256 lockRewardsClaimable;
  uint256 exposure;
}
```

### registry

```solidity
contract IAddressRegistry registry
```

Chedda address registry

### constructor

```solidity
constructor(address _registry) public
```

_Constructor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _registry | address | The address registry address. |

### accountSummary

```solidity
function accountSummary(address account) external view returns (struct AccountActor.AccountSummary)
```

Returns the account status summed up.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to return stats for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AccountActor.AccountSummary | the `AccountSummary` object containing account stats. |

### AccountPoolSummary

```solidity
struct AccountPoolSummary {
  uint256 supplied;
  uint256 borrowed;
  uint256 locked;
}
```

### allPositions

```solidity
function allPositions(address account, bool showActiveOnly) external view returns (struct AccountActor.Position[])
```

Returns an array containing tha accounts positions.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check |
| showActiveOnly | bool | If true only return positions in active pools, else return positions in all registered pools. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AccountActor.Position[] | Array of accounts positions |

### getPosition

```solidity
function getPosition(address account, address poolAddress) public view returns (struct AccountActor.Position)
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
| [0] | struct AccountActor.Position | The `Position` holding the values for the account position. If `account` does not have a position in this pool the numerical values are all zero. |


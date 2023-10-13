# Solidity API

## LendingPoolLens

Provides utility functions to view the state of LendingPools

### PoolStats

```solidity
struct PoolStats {
  address pool;
  address asset;
  string characterization;
  uint256 supplied;
  uint256 suppliedValue;
  uint256 borrowed;
  uint256 borrowedValue;
  uint256 baseSupplyAPY;
  uint256 maxSupplyAPY;
  uint256 baseBorrowAPY;
  uint256 maxBorrowAPY;
  uint256 utilization;
  uint256 feesPaid;
  uint256 tvl;
  address[] collaterals;
}
```

### AggregateStats

```solidity
struct AggregateStats {
  uint256 totalSuppliedValue;
  uint256 totalBorrowedValue;
  uint256 totalAvailableValue;
  uint256 totalFeesPaid;
  uint256 numberOfVaults;
  uint256 tvl;
}
```

### PoolCollateralInfo

```solidity
struct PoolCollateralInfo {
  address collateral;
  uint256 amountDeposited;
  uint256 value;
  uint256 collateralFactor;
}
```

### LendingPoolAccountInfo

```solidity
struct LendingPoolAccountInfo {
  uint256 totalSupplied;
  uint256 totalBorrowed;
  uint256 healthFactor;
}
```

### LendingPoolInfo

```solidity
struct LendingPoolInfo {
  uint256 assetOraclePrice;
  uint256 interestFeePercentage;
  uint256 liquidationThreshold;
  uint256 liquidationPenalty;
}
```

### AccountCollateralDeposited

```solidity
struct AccountCollateralDeposited {
  address token;
  uint256 amount;
  uint256 value;
  uint256[] tokenIds;
}
```

### AccountInfo

```solidity
struct AccountInfo {
  uint256 supplied;
  uint256 borrowed;
  uint256 healthFactor;
  uint256 totalCollateralValue;
  struct LendingPoolLens.AccountCollateralDeposited[] collateralDeposited;
}
```

### PoolRegistered

```solidity
event PoolRegistered(address pool, address caller)
```

### PoolUnregistered

```solidity
event PoolUnregistered(address pool, address caller)
```

### AlreadyRegistered

```solidity
error AlreadyRegistered(address pool)
```

### NotRegistered

```solidity
error NotRegistered(address pool)
```

### constructor

```solidity
constructor(address _owner) public
```

### registerPool

```solidity
function registerPool(address pool, bool isActive) external
```

Registers a new lending pool

_Can only be called by owner
Reverts if pools is already registered.
Emits PoolRegistered(address pool, address caller)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of pool. |
| isActive | bool | The active state of pool used for filtering. |

### unregisterPool

```solidity
function unregisterPool(address pool) external
```

Unregisters a lending pool

_Can only be called by admin. Reverts if pool is not registered
Emits PoolRegistered(address pool, address caller)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool to register |

### setActive

```solidity
function setActive(address pool, bool isActive) external
```

Sets a pool as active

_Pools can be filtered by their active state_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool to set active or inactive |
| isActive | bool | boolean flag to set pool as active or not |

### registeredPools

```solidity
function registeredPools() external view returns (address[])
```

Returns a list of all the registered pools

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | pools The addresses of all registered pools |

### activePools

```solidity
function activePools() external view returns (address[])
```

Returns a list of all the active pools

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | pools The addresses of all active pools |

### getAggregateStats

```solidity
function getAggregateStats() external view returns (struct LendingPoolLens.AggregateStats)
```

Explain to an end user what this does

_Explain to a developer any extra details_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.AggregateStats | aggregateStats The aggregated stats of the all registred pools |

### getPoolStatsList

```solidity
function getPoolStatsList(address[] pools) external view returns (struct LendingPoolLens.PoolStats[])
```

Returns various metrics of specified pools.

_Returns an array of `PoolStats` objects.
Reverts with NotRegistered(pool) error if a pool in the list is not registered._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pools | address[] | The list of pools to return stats for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.PoolStats[] | poolStats An array of `PoolStats` objects, containing the stats for specified pools. |

### getPoolStats

```solidity
function getPoolStats(address poolAddress) public view returns (struct LendingPoolLens.PoolStats)
```

Regturns the metrics of a specified pool.

_Reverts with `NotRegistered(address) error if the pool address is not registered._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The address of the pool to return stats for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.PoolStats | poolStats The `PoolStats` object containing the stats for specified pool. |

### getPoolAccountInfo

```solidity
function getPoolAccountInfo(address poolAddress, address account) external view returns (struct LendingPoolLens.AccountInfo)
```

Returns information about a given account in a specified pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The pool to return account info for. |
| account | address | The account to return info about. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.AccountInfo | info An `AccountInfo` obect about `account` position in the pool. |

### getPoolCollateral

```solidity
function getPoolCollateral(address poolAddress) external view returns (struct LendingPoolLens.PoolCollateralInfo[])
```

Returns information about colalteral in the pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The pool to return collateral info for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.PoolCollateralInfo[] | info The `PoolCollateralInfo` about collateral in the specified pool. |

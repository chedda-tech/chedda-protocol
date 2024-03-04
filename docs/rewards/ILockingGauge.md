# Solidity API

## Lock

The structure that represents an active lock.

```solidity
struct Lock {
  uint256 amount;
  uint256 timeWeighted;
  uint256 expiry;
  uint256 rewardDebt;
}
```

## LockTime

Enum representing the possible lock times

```solidity
enum LockTime {
  thirtyDays,
  ninetyDays,
  oneEightyDays,
  threeSixtyDays
}
```

## ILockingGauge

### weight

```solidity
function weight() external returns (uint256)
```

Returns the total amount of time weighted locked tokens.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The time weighted locked tokens. |

### createLock

```solidity
function createLock(uint256 amount, enum LockTime time) external returns (uint256)
```

Locks CHEDDA token for the given lock time.

_Explain to a developer any extra details_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The token amount to lock |
| time | enum LockTime | The lock time. This is specified by the `LockTime` enum. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The expiry of the created lock |

### withdraw

```solidity
function withdraw() external returns (uint256)
```

Withdraws locked CHEDDA after the lock expires

_A lock must exist and must have already expired for this call to succeed._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of CHEDDA withdrawn. This is equal to the total amount of  CHEDDA previously locked by the caller. |

### getLock

```solidity
function getLock(address account) external view returns (struct Lock)
```

Returns the `Lock` struct for the given account if it exists.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | THe account to return the lock for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Lock | The lock info. |

### claim

```solidity
function claim() external returns (uint256)
```

Claims any pending rewards

_Rewards are available if a lock exists and rewards have been distributed
to this locking pool._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of reward tokens received. |

### claimable

```solidity
function claimable(address account) external view returns (uint256)
```

Returns the accrued token reward amount that can currently be claimed  by a given account.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to return reward amount for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of claimable rewards. |

### addRewards

```solidity
function addRewards(uint256 amount) external
```

Adds token rewards to this pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to add. |


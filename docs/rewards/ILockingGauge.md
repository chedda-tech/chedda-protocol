# Solidity API

## LockTime

Enum representing the possible lock times

```solidity
enum LockTime {
  zero,
  thirtyDays,
  ninetyDays,
  oneEightyDays,
  threeSixtyDays
}
```

## Lock

The structure that represents an active lock.

```solidity
struct Lock {
  uint256 amount;
  uint256 timeWeighted;
  uint256 expiry;
  uint256 rewardDebt;
  enum LockTime lockTime;
}
```

## ILockingGauge

### token

```solidity
function token() external view returns (contract ICheddaToken)
```

The token locked to this gauge.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ICheddaToken | The token address. |

### totalWeight

```solidity
function totalWeight() external view returns (uint256)
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

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The token amount to lock |
| time | enum LockTime | The lock time. This is specified by the `LockTime` enum. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The expiry of the created lock |

### extendLock

```solidity
function extendLock(enum LockTime time) external returns (uint256)
```

Extends an existing lock.

_A lock owned by the caller must already exist.
is the current time + length of lock based on lock time._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| time | enum LockTime | The new time for the lock. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The new expiry for the lock |

### addToLock

```solidity
function addToLock(uint256 amount) external returns (uint256)
```

Adds more CHEDDA to an existing lock. This does not change the lock expiry.

_A lock owned by the caller must already exist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of CHEDDA to add to the lock. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The total amoun tlocked by the user. |

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

Returns the `Lock` struct for the given account.

_Note: A `Lock` is always returned by this function.
If a valid lock exists, the `amount` field is non-zero. A zero `amount`
means a valid lock does not exist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | THe account to return the lock for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Lock | The lock info. |

### claimFor

```solidity
function claimFor(address account) external returns (uint256)
```

Claim pending rewards for another account.

_Emits `RewardsClaimed(address, uint)` event.
Can only be called by `AccountActor` contract._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount claimed |

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


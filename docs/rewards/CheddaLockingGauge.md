# Solidity API

## CheddaLockingGauge

Manages the amount of CHEDDA locked in each pool.

### LockCreated

```solidity
event LockCreated(address account, uint256 amount, uint256 expiry)
```

Emitted when a lock is created or updated.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account creating a lock. |
| amount | uint256 | The amount locked. |
| expiry | uint256 | The lock expiry |

### LockModified

```solidity
event LockModified(address account, uint256 amount, uint256 expiry)
```

Emitted when a lock is extended or has more CHEDDA added to added.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account creating a lock. |
| amount | uint256 | The amount locked. |
| expiry | uint256 | The lock expiry |

### Withdrawn

```solidity
event Withdrawn(address account, uint256 amount)
```

Emitted when a lock is destroyed and locked tokens are withdrawn.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account creating a lock. |
| amount | uint256 | The amount locked. |

### Claimed

```solidity
event Claimed(address account, uint256 amount)
```

Emitted when rewards are claimed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account claiming rewards. |
| amount | uint256 | The amount claimed. |

### RewardsAdded

```solidity
event RewardsAdded(address caller, uint256 amount)
```

Emmitted when rewards are added to this gauge

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | The caller of the function that emitted this event. |
| amount | uint256 | The amount of rewards added. |

### ReducedLockTime

```solidity
error ReducedLockTime()
```

### InvalidLockTime

```solidity
error InvalidLockTime(enum LockTime)
```

### LockExists

```solidity
error LockExists(address)
```

### LockNotFound

```solidity
error LockNotFound(address)
```

### LockNotExpired

```solidity
error LockNotExpired(uint256)
```

### ZeroAmount

```solidity
error ZeroAmount()
```

### InvalidAmount

```solidity
error InvalidAmount(uint256)
```

### NotAuthorized

```solidity
error NotAuthorized(address caller)
```

_Thrown when account other than rewardsDistributor calls the `addRewards()` function._

### registry

```solidity
contract IAddressRegistry registry
```

### token

```solidity
contract ICheddaToken token
```

The token locked to this gauge.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### rewardPerShare

```solidity
uint256 rewardPerShare
```

### totalLocked

```solidity
uint256 totalLocked
```

### totalClaimed

```solidity
uint256 totalClaimed
```

### totalRewards

```solidity
uint256 totalRewards
```

### totalWeight

```solidity
uint256 totalWeight
```

Returns the total amount of time weighted locked tokens.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### numberOfLocks

```solidity
uint256 numberOfLocks
```

### constructor

```solidity
constructor(address _registry) public
```

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

### claimFor

```solidity
function claimFor(address account) public returns (uint256)
```

### _claimFor

```solidity
function _claimFor(address account) internal returns (uint256)
```

_Internal claim function._

### claimable

```solidity
function claimable(address account) public view returns (uint256)
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


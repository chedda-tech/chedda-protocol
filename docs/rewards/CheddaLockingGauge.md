# Solidity API

## CheddaLockingGauge

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
| expiry | uint256 |  |

### Withdrawn

```solidity
event Withdrawn(address account, uint256 amount)
```

### Claimed

```solidity
event Claimed(address account, uint256 amount)
```

### RewardsAdded

```solidity
event RewardsAdded(address caller, uint256 amount)
```

### ReducedLockTime

```solidity
error ReducedLockTime()
```

### InvalidTime

```solidity
error InvalidTime(enum LockTime)
```

### LockNotExpired

```solidity
error LockNotExpired(uint256)
```

### NoLockFound

```solidity
error NoLockFound(address)
```

### ZeroAmount

```solidity
error ZeroAmount()
```

### InvalidAmount

```solidity
error InvalidAmount(uint256)
```

### token

```solidity
contract IERC20 token
```

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

### weight

```solidity
uint256 weight
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
constructor(address _token) public
```

### createLock

```solidity
function createLock(uint256 amount, enum LockTime time) external returns (uint256)
```

@inheritdoc	ILockingGauge

### withdraw

```solidity
function withdraw() external returns (uint256)
```

@inheritdoc	ILockingGauge

### getLock

```solidity
function getLock(address account) external view returns (struct Lock)
```

@inheritdoc	ILockingGauge

### claim

```solidity
function claim() external returns (uint256)
```

@inheritdoc	ILockingGauge

### _claim

```solidity
function _claim(address account) internal returns (uint256)
```

_Internal claim function._

### claimable

```solidity
function claimable(address account) public view returns (uint256)
```

@inheritdoc	ILockingGauge

### addRewards

```solidity
function addRewards(uint256 amount) external
```

@inheritdoc	ILockingGauge


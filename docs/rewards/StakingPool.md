# Solidity API

## StakingPool

Manages staking tokens and rewards.

### Staked

```solidity
event Staked(address account, uint256 amount)
```

Emitted when a user stakes tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that staked. |
| amount | uint256 | The amount staked. |

### Unstaked

```solidity
event Unstaked(address account, uint256 amount)
```

Emitted when a user unstakes tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that unstaked. |
| amount | uint256 | The amount unstaked. |

### RewardsClaimed

```solidity
event RewardsClaimed(address account, uint256 amount)
```

Emitted when rewards are claimed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that claimed. |
| amount | uint256 | The amount wclaimed. |

### RewardsAdded

```solidity
event RewardsAdded(uint256 amount)
```

Emitted when rewards are added to the reward pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount added. |

### InsufficientStake

```solidity
error InsufficientStake()
```

_Thrown when user tries to unstake more than their staking balance._

### NotAuthorized

```solidity
error NotAuthorized(address caller)
```

_Thrown when account other than rewardsDistributor calls the `addRewards()` function._

### NoStakeFound

```solidity
error NoStakeFound(address caller)
```

_Thrown when user tries to unstake when they don't have tokens staked._

### ZeroAmount

```solidity
error ZeroAmount()
```

_Thrown when user tries to stake or unstake the zero amount._

### InvalidAmount

```solidity
error InvalidAmount(uint256 amount)
```

_Thrown when an invalid amount of rewards are added._

### UserInfo

```solidity
struct UserInfo {
  uint256 amountStaked;
  uint256 rewardDebt;
}
```

### userInfo

```solidity
mapping(address => struct StakingPool.UserInfo) userInfo
```

### stakingToken

```solidity
contract IERC20 stakingToken
```

The staking token

### rewardToken

```solidity
contract IRebaseToken rewardToken
```

The reward token

### totalStaked

```solidity
uint256 totalStaked
```

Total amount of tokens staked

### stakers

```solidity
uint256 stakers
```

The number of unique stakers

### rewardPerShare

```solidity
uint256 rewardPerShare
```

Current reward per share

### constructor

```solidity
constructor(address _stakingToken, address _rewardToken) public
```

Constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _stakingToken | address | The token being staked. |
| _rewardToken | address | The reward token. |

### stake

```solidity
function stake(uint256 amount) external returns (uint256)
```

Stakes tokens to earn rewards.

_Unstaking claims any pending rewards._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to unstake. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of rewards claimed. |

### unstake

```solidity
function unstake(uint256 amount) external returns (uint256)
```

Unstakes previously staked tokens

_Unstaking claims any pending rewards._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to unstake. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of rewards claimed |

### claim

```solidity
function claim() public returns (uint256)
```

Claim any pending rewards.

_Emits `RewardsClaimed(address, uint)` event._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount claimed. |

### claimable

```solidity
function claimable(address account) public view returns (uint256)
```

Returns pending rewards for given account.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to get the pending rewards for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of rewards that can currently be claimed by this account |

### stakingBalance

```solidity
function stakingBalance(address account) external view returns (uint256)
```

Returns the staking balance of a given account.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to return staking balance for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount staked by account |

### addRewards

```solidity
function addRewards(uint256 amount) external
```

Adds rewards to the pool

_Can only be called by the rewarder set in the `AddressRegistry`.
Caller must have previously approved this contract to `transferFrom` amount.
    emits `RewardsAdded(uint amount)` event._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of rewards to add. |


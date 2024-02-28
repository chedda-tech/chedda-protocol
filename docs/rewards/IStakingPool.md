# Solidity API

## IStakingPool

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
function claim() external returns (uint256)
```

Claim any pending rewards.

_Emits `RewardsClaimed(address, uint)` event._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount claimed. |

### claimable

```solidity
function claimable(address account) external view returns (uint256)
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


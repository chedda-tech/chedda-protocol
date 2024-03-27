# Solidity API

## IRewardsDistributor

Interface implmented to distribute rewards. Rewards are distributed based on internal logic
thus, it's up to the implementation to define the reward distribution strategy.

### distribute

```solidity
function distribute() external returns (uint256)
```

Distributes rewwards to registered pools based on internal logic.

_Explain to a developer any extra details_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of token distributed. |

### weightTotal

```solidity
function weightTotal() external returns (uint256)
```

Returns the total weight of all the pools.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The total weight of all registered pools. |


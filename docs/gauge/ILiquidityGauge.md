# Solidity API

## ILiquidityGauge

### claim

```solidity
function claim() external
```

### rollover

```solidity
function rollover(uint256 balance, uint256 weight, uint256 rate) external
```

### setRewardRate

```solidity
function setRewardRate(uint256 rate) external
```

### recordVote

```solidity
function recordVote(address account) external
```

### rewardToken

```solidity
function rewardToken() external view returns (address)
```

### rewardRate

```solidity
function rewardRate() external view returns (uint256)
```


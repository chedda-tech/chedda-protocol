# Solidity API

## ICheddaPool

### setGauge

```solidity
function setGauge(address gauge) external
```

### setStakingPool

```solidity
function setStakingPool(address stakingPool) external
```

### gauge

```solidity
function gauge() external view returns (contract ILockingGauge)
```

### stakingPool

```solidity
function stakingPool() external view returns (contract IStakingPool)
```


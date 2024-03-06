# Solidity API

## LockingGaugeRewardsDistributor

Distributes token rewards to pools proportionally based on the pool's
`weight`.

### AlreadyRegistered

```solidity
error AlreadyRegistered(address)
```

### NotFound

```solidity
error NotFound(address)
```

### PoolRegistered

```solidity
event PoolRegistered(address pool)
```

### PoolUnregistered

```solidity
event PoolUnregistered(address pool)
```

### RewardsDistributed

```solidity
event RewardsDistributed(uint256 amount)
```

### token

```solidity
contract IERC20 token
```

### pools

```solidity
contract ICheddaPool[] pools
```

### stakingPortion

```solidity
uint256 stakingPortion
```

### lockingPortion

```solidity
uint256 lockingPortion
```

### Konstant

```solidity
uint256 Konstant
```

### constructor

```solidity
constructor(address _token, address _admin) public
```

Constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | address | The address of token to be distributed |
| _admin | address | The contract admin. This account can register and unregister pools. |

### registerPool

```solidity
function registerPool(contract ICheddaPool _pool) external
```

Registers a pool to receive rewards.

_Can only be called by contract owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pool | contract ICheddaPool | Address of the pool. |

### unregisterPool

```solidity
function unregisterPool(contract ICheddaPool _pool) external
```

Unregisters a pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pool | contract ICheddaPool | Address of pool to unregister. Must have been previously registered. |

### distribute

```solidity
function distribute() external returns (uint256)
```

@inheritdoc	IRewardsDistributor


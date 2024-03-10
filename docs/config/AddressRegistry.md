# Solidity API

## AddressRegistry

Stores and retrieves commonly used addresses on the protocol.

### RewardsDistributorSet

```solidity
event RewardsDistributorSet(address caller, address distributor)
```

### CheddaSet

```solidity
event CheddaSet(address caller, address chedda)
```

### PoolRegistered

```solidity
event PoolRegistered(address pool, address caller)
```

### PoolUnregistered

```solidity
event PoolUnregistered(address pool, address caller)
```

### AlreadyRegistered

```solidity
error AlreadyRegistered(address pool)
```

### NotRegistered

```solidity
error NotRegistered(address pool)
```

### constructor

```solidity
constructor(address admin) public
```

### rewardsDistributor

```solidity
function rewardsDistributor() external view returns (address)
```

@inheritdoc	IAddressRegistry

### cheddaToken

```solidity
function cheddaToken() external view returns (address)
```

@inheritdoc	IAddressRegistry

### setRewardsDistributor

```solidity
function setRewardsDistributor(address distributor) external
```

Sets the rewards distributor

_Can only be called by the owner. 
emits RewardsDistributorSet(address caller, address distributor) event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| distributor | address | The new rewards distributor |

### setCheddaToken

```solidity
function setCheddaToken(address chedda) external
```

Explain to an end user what this does

_Can only be called by the owner. 
emits CheddaSet(address caller, address cheddaToken) event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chedda | address | New chedda token address |

### registerPool

```solidity
function registerPool(address pool, bool isActive) external
```

Registers a new lending pool

_Can only be called by owner
Reverts if pools is already registered.
Emits PoolRegistered(address pool, address caller)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of pool. |
| isActive | bool | The active state of pool used for filtering. |

### unregisterPool

```solidity
function unregisterPool(address pool) external
```

Unregisters a lending pool

_Can only be called by admin. Reverts if pool is not registered
Emits PoolRegistered(address pool, address caller)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool to register |

### setActive

```solidity
function setActive(address pool, bool isActive) external
```

Sets a pool as active

_Pools can be filtered by their active state_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool to set active or inactive |
| isActive | bool | boolean flag to set pool as active or not |

### isRegisteredPool

```solidity
function isRegisteredPool(address pool) public view returns (bool)
```

checks if a pool is already registered

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address to check for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true if the pool address is registered |

### isActivePool

```solidity
function isActivePool(address pool) public view returns (bool)
```

checks if a pool is active

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address to check for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true if the pool address is registered |

### registeredPools

```solidity
function registeredPools() external view returns (address[])
```

Returns a list of all the registered pools

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | pools The addresses of all registered pools |

### activePools

```solidity
function activePools() external view returns (address[])
```

Returns a list of all the active pools

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | pools The addresses of all active pools |


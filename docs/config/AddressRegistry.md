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

### constructor

```solidity
constructor() public
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


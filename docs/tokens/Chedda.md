# Solidity API

## Chedda

Chedda token

### TokenRebased

```solidity
event TokenRebased(address caller, uint256 amountMinted, uint256 newTotalSupply)
```

Emitted when the new token is minted in a rebase

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | The caller of the rebase function |
| amountMinted | uint256 | The increase in token supply |
| newTotalSupply | uint256 | The `totalSupply` after the rebase. |

### StakingVaultSet

```solidity
event StakingVaultSet(address caller, address vault)
```

emitted when the stkaing vault address is set.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | The caller of the function that triggered this event. |
| vault | address | The new staking vault address. |

### GaugeRecipientSet

```solidity
event GaugeRecipientSet(address caller, address recipient)
```

emitted when the gauge recipient address is set.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | The caller of the function that triggered this event. |
| recipient | address | The new gauge recipient address. |

### ZeroAddress

```solidity
error ZeroAddress()
```

_thrown if zero-address is used where it should not be_

### INITIAL_SUPPLY

```solidity
uint256 INITIAL_SUPPLY
```

The inital total supply

### DECIMALS

```solidity
uint8 DECIMALS
```

The number of decimals

### stakingShare

```solidity
UD60x18 stakingShare
```

### tge

```solidity
uint256 tge
```

the token generation event timestamp.

### lastRebase

```solidity
uint256 lastRebase
```

The timestamp of the last rebase.

### stakingVault

```solidity
address stakingVault
```

The staking vault address that receive staking rewards.

### gaugeRecipient

```solidity
address gaugeRecipient
```

The gauge controller address.

### constructor

```solidity
constructor(address custodian) public
```

Construct a new Chedda token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| custodian | address | The token custodian to mint initial supply to. |

### setStakingVault

```solidity
function setStakingVault(address _vault) external
```

Sets the staking vault address to recieve staking rewards

_Can only be called by `owner`. Emits StakingVaultSet(caller, vault) event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _vault | address | The new staking vault |

### setGaugeRecipient

```solidity
function setGaugeRecipient(address _recipient) external
```

Sets the gauge recipient address to recieve token emission rewards

_Can only be called by `owner`. Emits GaugeRecipientSet(caller, _recipient) event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _recipient | address | The new gauge recipient |

### rebase

```solidity
function rebase() external returns (uint256)
```

Increases the total supply of CHEDDA token according to the emission schedule.

_Explain to a developer any extra details_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amountMinted The increment in token total supply. |

### emissionPerSecond

```solidity
function emissionPerSecond() public view returns (uint256)
```

Returns the amount of CHEDDA token emitted each second, 
as controlled by the emission schedule.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | emission The amount of CHEDDA token emitted each second. |

### epoch

```solidity
function epoch() public view returns (uint256)
```

Returns the number of the current epoch

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | epoch The current epoch |


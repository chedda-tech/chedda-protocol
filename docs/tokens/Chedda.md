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

### TokenReceiverSet

```solidity
event TokenReceiverSet(address caller, address receiver)
```

emitted when the gauge recipient address is set.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | The caller of the function that triggered this event. |
| receiver | address | The new receiver address. |

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

### MAX_TOTAL_SUPPLY

```solidity
uint256 MAX_TOTAL_SUPPLY
```

### DECIMALS

```solidity
uint8 DECIMALS
```

The number of decimals

### EPOCH_LENGTH

```solidity
uint256 EPOCH_LENGTH
```

_The length of an epoch. Token emission reduces by half each epoch_

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

### tokenReceiver

```solidity
address tokenReceiver
```

The receiver for new token emissions.

### constructor

```solidity
constructor(address custodian) public
```

Construct a new Chedda token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| custodian | address | The token custodian to mint initial supply to. |

### setTokenReceiver

```solidity
function setTokenReceiver(address _receiver) external
```

Sets the address to recieve token emission.

_Can only be called by `owner`. Emits TokenReceiverSet(caller, _receiver) event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _receiver | address | The new token recipient |

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


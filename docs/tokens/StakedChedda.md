# Solidity API

## StakedChedda

Tokenized vault representing staked CHEDDA rewards.

_Must be set as CHEDDA token vault for new token emission._

### Staked

```solidity
event Staked(address account, uint256 amount, uint256 shares)
```

Emitted when CHEDDA is staked.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that staked. |
| amount | uint256 | The amount of CHEDDA staked. |
| shares | uint256 | The amount of xCHEDDA minted. |

### Unstaked

```solidity
event Unstaked(address account, uint256 amount, uint256 shares)
```

Emitted when CHEDDA is unstaked.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that unstaked. |
| amount | uint256 | The amount of CHEDDA unstaked. |
| shares | uint256 | The amount of xCHEDDA burned. |

### chedda

```solidity
contract IRebaseToken chedda
```

### constructor

```solidity
constructor(address _chedda) public
```

### totalAssets

```solidity
function totalAssets() public view returns (uint256)
```

Total amount of CHEDDA staked.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of CHEDDA staked |

### stake

```solidity
function stake(uint256 amount) public returns (uint256 shares)
```

Stake CHEDDA.

_mints xCHEDDA_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount to stake. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | Amount of xCHEDDA minted. |

### unstake

```solidity
function unstake(uint256 shares) public returns (uint256 amount)
```

Unstake CHEDDA.

_burns xCHEDDA._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | Shares of xCHEDDA to redeem |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount of CHEDDA retruned by redeeming xCHEDDA. |


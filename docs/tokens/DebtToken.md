# Solidity API

## DebtToken

This is the unit of account of debt in a lending pool.

_Implements the ERC4626 interface._

### DebtCreated

```solidity
event DebtCreated(address account, uint256 amount, uint256 shares)
```

Emitted when debt is created

### DebtRepaid

```solidity
event DebtRepaid(address account, uint256 amount, uint256 shares)
```

Emitted when debt is repaid

### DebtAccrued

```solidity
event DebtAccrued(uint256 totalDebt, uint256 interest)
```

Emitted when debt accrual takes place.

### NonTransferrable

```solidity
error NonTransferrable()
```

### ZeroAssets

```solidity
error ZeroAssets()
```

### ZeroShares

```solidity
error ZeroShares()
```

### NotVault

```solidity
error NotVault()
```

### STARTING_INTEREST_RATE_PER_SECOND

```solidity
uint64 STARTING_INTEREST_RATE_PER_SECOND
```

### ONE_PERCENT

```solidity
uint64 ONE_PERCENT
```

### PER_SECOND

```solidity
uint64 PER_SECOND
```

### vault

```solidity
address vault
```

The vault address

### onlyVault

```solidity
modifier onlyVault()
```

### constructor

```solidity
constructor(contract ERC20 _asset, address _vault) public
```

Creates a debt token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _asset | contract ERC20 | the asset being borrowed. |
| _vault | address | the Chedda vault this asset is being borrowed from. |

### createDebt

```solidity
function createDebt(uint256 amount, address account) external returns (uint256 shares)
```

records the creation of debt. `account` borrowed `amount` of underlying token.

_Explain to a developer any extra details_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount borrowed |
| account | address | The account doing the borrowing |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The number of tokens minted to track this debt + future interest payments. |

### repayShare

```solidity
function repayShare(uint256 shares, address account) external returns (uint256 amount)
```

records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The portion of debt to repay |
| account | address | The account repaying |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of debt repaid |

### repayAmount

```solidity
function repayAmount(uint256 amount, address account) external returns (uint256 shares)
```

records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to repay |
| account | address | The account repaying |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The shares burned by repaying this debt. |

### accountShare

```solidity
function accountShare(address account) external view returns (uint256)
```

Returns the amount of shares a given account has

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to return the balance for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | shares The number of shares |

### assetsPerShare

```solidity
function assetsPerShare() public view virtual returns (uint256)
```

_amount of assets owed per share_

### totalAssets

```solidity
function totalAssets() public view returns (uint256)
```

Returns total owed (amount borrowed + outstanding interest payments).

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | totalDebt Total outstanding debt todo: change to totalDebt |

### totalBorrowed

```solidity
function totalBorrowed() external view returns (uint256 borrowed)
```

TODO: Change asset references besides underlying `asset` to debt.
e.g totalAssets(), assetsPerShare(), 
Returns the total principal amount of debt tracked.

_This does not include any future interest payments._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| borrowed | uint256 | Total amount of debt (principal) tracked. |

### transfer

```solidity
function transfer(address, uint256) public pure returns (bool)
```

_Reverts with `NonTransferrable()` error. Debt tokens are non-transferrable_

### transferFrom

```solidity
function transferFrom(address, address, uint256) public pure returns (bool)
```

_Reverts with `NonTransferrable()` error. Debt tokens are non-transferrable_

### accrue

```solidity
function accrue() external
```

Accrues interest

_External wrapper to internal `_accrue()` function._


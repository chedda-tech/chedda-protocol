# Solidity API

## LendingPool

TODO: check prices are positive and no overflow/underflow when using prices

### TokenType

_The type of the collateral.
Options are ERC20, ERC721 and ERC1155._

```solidity
enum TokenType {
  ERC20,
  ERC721,
  ERC155
}
```

### CollateralInfo

Holds information about the type of collateral held in vault.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct CollateralInfo {
  address token;
  uint256 collateralFactor;
  enum LendingPool.TokenType tokenType;
}
```

### VaultStateView

Custom errors
This is the current state of vault key stats, returned as a view.
Some fields are computed.

_move to LendingPoolView?_

```solidity
struct VaultStateView {
  uint256 supplied;
  uint256 borrowed;
  uint256 available;
  uint256 utilization;
  uint256 baseSupplyApr;
  uint256 baseBorrowApr;
  uint256 maxSupplyRewardsApr;
  uint256 maxBorrowRewardsApr;
  uint256 max;
}
```

### CollateralDeposited

_Information about collateral deposited to the pool._

```solidity
struct CollateralDeposited {
  address token;
  enum LendingPool.TokenType tokenType;
  uint256 amount;
  uint256[] tokenIds;
}
```

### AccountCollateralValue

_The value of a collateral token deposited by an account._

```solidity
struct AccountCollateralValue {
  address token;
  uint256 amount;
  int256 value;
}
```

### CollateralAdded

```solidity
event CollateralAdded(address token, address account, enum LendingPool.TokenType ofType, uint256 amount)
```

Emitted when collateral is added

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token added |
| account | address | The account that added the collateral. |
| ofType | enum LendingPool.TokenType | The type of collateral |
| amount | uint256 | The amount of token added as collateral |

### CollateralRemoved

```solidity
event CollateralRemoved(address token, address account, enum LendingPool.TokenType ofType, uint256 amount)
```

Emitted when collateral is removed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token removed. |
| account | address | The account that removed the collateral. |
| ofType | enum LendingPool.TokenType | The type of collateral |
| amount | uint256 | The amount of token removed as collateral |

### AssetBorrowed

```solidity
event AssetBorrowed(address account, uint256 amount, uint256 debtMinted)
```

Emitted when assets are borrowed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that borrowed assets. |
| amount | uint256 | The amount of assets borrowed. |
| debtMinted | uint256 | The amount of debt token created. |

### AssetRepaid

```solidity
event AssetRepaid(address account, uint256 amount, uint256 debtBurned)
```

Emitted when borrowed assets are repaid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that repaid assets. |
| amount | uint256 | The amount of assets repaid. |
| debtBurned | uint256 | The amount of debt token burned. |

### GaugeSet

```solidity
event GaugeSet(address gauge, address caller)
```

Emitted when the rewards gauge is set

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| gauge | address | The gauge address. |
| caller | address | The account that set the gauge. |

### CheddaPool_InvalidPrice

```solidity
error CheddaPool_InvalidPrice(int256 price, address token)
```

Custom errors

### CheddaPool_CollateralNotAllowed

```solidity
error CheddaPool_CollateralNotAllowed(address token)
```

### CheddaPool_WrongCollateralType

```solidity
error CheddaPool_WrongCollateralType(address token)
```

### CheddaPool_ZeroAmount

```solidity
error CheddaPool_ZeroAmount()
```

### CheddaPool_InsufficientCollateral

```solidity
error CheddaPool_InsufficientCollateral(address account, address token, uint256 amountRequested, uint256 amountDeposited)
```

### CheddaPool_AccountInsolvent

```solidity
error CheddaPool_AccountInsolvent(address account, uint256 health)
```

### CheddaPool_InsufficientAssetBalance

```solidity
error CheddaPool_InsufficientAssetBalance(uint256 available, uint256 requested)
```

### CheddaPool_Overpayment

```solidity
error CheddaPool_Overpayment()
```

### supplied

```solidity
uint256 supplied
```

state vars

### feesPaid

```solidity
uint256 feesPaid
```

### characterization

```solidity
string characterization
```

### debtToken

```solidity
contract DebtToken debtToken
```

Debt and interest

### priceFeed

```solidity
contract IPriceFeed priceFeed
```

### interestRates

```solidity
struct InterestRates interestRates
```

### interestRateModel

```solidity
contract IInterestRateModel interestRateModel
```

### gauge

```solidity
contract ILiquidityGauge gauge
```

### collateralTokenList

```solidity
address[] collateralTokenList
```

Collateral

### collateralAllowed

```solidity
mapping(address => bool) collateralAllowed
```

### collateralTokenTypes

```solidity
mapping(address => enum LendingPool.TokenType) collateralTokenTypes
```

### collateralFactor

```solidity
mapping(address => uint256) collateralFactor
```

### accountCollateralDeposited

```solidity
mapping(address => mapping(address => struct LendingPool.CollateralDeposited)) accountCollateralDeposited
```

### tokenCollateralDeposited

```solidity
mapping(address => uint256) tokenCollateralDeposited
```

### constructor

```solidity
constructor(string _name, contract ERC20 _asset, address _priceFeed, struct LendingPool.CollateralInfo[] _collateralTokens) public
```

initialization

### supply

```solidity
function supply(uint256 amount, address receiver, bool useAsCollateral) external returns (uint256)
```

Supplies assets to pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to supply |
| receiver | address | The account to mint share tokens to |
| useAsCollateral | bool | Whethe this deposit should be marked as collateral |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | shares The amount of shares minted. |

### withdraw

```solidity
function withdraw(uint256 assetAmount, address receiver, address owner) public returns (uint256)
```

Withdraws a specified amount of assets from pool

_If user has added this asset as collateral a collateral amount will be removed.
if owner != msg.sender there must be an existing approval >= assetAmount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| assetAmount | uint256 | The amount to withdraw |
| receiver | address | The account to receive withdrawn assets |
| owner | address | The account to withdraw assets from. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | shares The amount of shares burned by withdrawal. |

### redeem

```solidity
function redeem(uint256 shares, address receiver, address owner) public returns (uint256)
```

Withdraws and burns a specified amount of shares.

_If user has added this asset as collateral a collateral amount will be removed.
if owner != msg.sender there must be an existing approval >= assetAmount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The share amount to redeem. |
| receiver | address | The account to receive withdrawn assets |
| owner | address | The account to withdraw assets from. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | assetAmount The amount of assets repaid. |

### take

```solidity
function take(uint256 amount) external returns (uint256)
```

Borrows asset from the pool.

_The max amount a user can borrow must be less than the value of their collateral weighted
against the loan to value ratio of that colalteral.
Emits AssetBorrowed(account, amount, debt) event._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to borrow |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | debt The amount of debt token minted. |

### putAmount

```solidity
function putAmount(uint256 amount) external returns (uint256)
```

Repays a part or all of a loan.

_Emits AssetRepaid(account, amount, debtBurned)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | amount to repay. Must be > 0 and <= amount borrowed by sender |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of debt shares burned by this repayment. |

### putShares

```solidity
function putShares(uint256 shares) external returns (uint256)
```

Repays a part or all of a loan by specifying the amount of debt token to repay.

_Emits AssetRepaid(account, amountRepaid, shares)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The share of debt token to repay. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amountRepaid the amount repaid. |

### addCollateral

```solidity
function addCollateral(address token, uint256 amount) external
```

Add ERC-20 token collateral to pool.

_Emits CollateralAdded(address token, address account, uint tokenType, uint amount)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token to deposit as collateral. |
| amount | uint256 | The amount of token to deposit. |

### removeCollateral

```solidity
function removeCollateral(address token, uint256 amount) external
```

Removes ERC20 collateral from pool.

_Emits CollateralRemoved(token, account, type, amount)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The collateral token to remove. |
| amount | uint256 | The amount to remove. |

### accountCollateralTokenIds

```solidity
function accountCollateralTokenIds(address account, address collateral) external view returns (uint256[])
```

Get the token IDs deposited by this account

_`collateral` parameter should be an ERC-721 token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check for |
| collateral | address | The collateral to check for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | tokenIds the token ids from the `collateral` NFT deposited by `account`. |

### totalAccountCollateralValue

```solidity
function totalAccountCollateralValue(address account) public view returns (uint256)
```

Returns the total value of collateral deposited by an account.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to get collateral value for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | totalValue The value of collateral deposited by account. |

### accountCollateralAmount

```solidity
function accountCollateralAmount(address account, address collateral) public view returns (uint256)
```

TODO: remove. Renamed from `accountCollateralCount`.
Returns the amount of a given token an account has deposited as collateral

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check collateral for |
| collateral | address | The collateral to check |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amount The amount of `collateral` token `account` has deposited. |

### accountAssetsBorrowed

```solidity
function accountAssetsBorrowed(address account) public view returns (uint256)
```

TODO: remove. Renamed from `accountPendingAmount`
Returns the amount of asset an account has borrowed, including any accrued interest.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amount The amount of account borrowed by `account`. |

### debtValue

```solidity
function debtValue(uint256 assetAmount) public view returns (uint256)
```

### accountHealth

```solidity
function accountHealth(address account) public view returns (uint256)
```

Returns the health ratio of the account
health > 1.0 means the account is solvent.
health <1.0 but != 0 means account is insolvent
health == 0 means account has no debt and is also solvent.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | health The health ration of the account, to 1e18. i.e 1e18 = 1.0 health. |

### collaterals

```solidity
function collaterals() external view returns (address[])
```

### getTokenMarketValue

```solidity
function getTokenMarketValue(address token, uint256 amount) public view returns (uint256)
```

Returns the market value of a given number of token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token to return value for. |
| amount | uint256 | The amount of token to calculate the value of. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | value The market value of `amount` of `token`. |

### getTokenCollateralValue

```solidity
function getTokenCollateralValue(address token, uint256 amount) public view returns (uint256)
```

Returns the value as collateral for a given amount of token

_This takes into account the collateral factor of the token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token to return value for. |
| amount | uint256 | The amount of token to calculate the value of. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | value The collateral value of `amount` of `token`. |

### poolAsset

```solidity
function poolAsset() public view returns (contract ERC20)
```

Returns the asset that can be borrowed from this pool

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ERC20 | asset The pool asset |

### assetBalance

```solidity
function assetBalance(address account) external view returns (uint256)
```

The amount of asset an account can access.

_This is based on the number of pool shares an account holds._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check the balance of. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amount The amount of asset an account holds in the pool. |

### totalAssets

```solidity
function totalAssets() public view returns (uint256)
```

The total amount of asset deposited into the pool.

_This includes assets that have been borrowed._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amount The total assets supplied to pool. |

### available

```solidity
function available() public view returns (uint256)
```

The assets available to be borrowed from pool.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | assetAmount The amount of asset available in pool. |

### borrowed

```solidity
function borrowed() public view returns (uint256)
```

The assets borrowed from pool.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | assetAmount The amount of asset borrowed from pool. |

### tvl

```solidity
function tvl() external view returns (uint256)
```

The total value locked in this pool.

_TVL is calculated as assets supplied + collateral deposited._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | tvl The total value locked in pool. |

### baseSupplyAPY

```solidity
function baseSupplyAPY() external view returns (uint256)
```

Returns the base supply APY.

_This is the interest earned on supplied assets._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | apy The interest earned on supplied assets. |

### baseBorrowAPY

```solidity
function baseBorrowAPY() external view returns (uint256)
```

Returns the base borrow APY.

_This is the interest paid on borrowed assets._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | apy The interest paid on borrowed assets. |

### utilization

```solidity
function utilization() public view returns (uint256)
```

The pool asset utilization

_This is the amount of asset borrowed divided by assets supplied._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | utilization The pool asset utilization. |

### setGauge

```solidity
function setGauge(address _gauge) external
```

Set the rewards gauge for this pool.

_Can only be called by contract owner
Emits GaugeSet(gauge, caller)._

### beforeWithdraw

```solidity
function beforeWithdraw(uint256 assets, uint256 shares) internal
```

deposit/withdraw hooks

### afterDeposit

```solidity
function afterDeposit(uint256 assets, uint256 shares) internal
```


# Solidity API

## LendingPool

Implements supply and borrow functionality.

_Implements ERC4626 interface._

### CollateralAdded

```solidity
event CollateralAdded(address token, address account, enum TokenType ofType, uint256 amount)
```

Emitted when collateral is added

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token added |
| account | address | The account that added the collateral. |
| ofType | enum TokenType | The type of collateral |
| amount | uint256 | The amount of token added as collateral |

### CollateralRemoved

```solidity
event CollateralRemoved(address token, address account, enum TokenType ofType, uint256 amount)
```

Emitted when collateral is removed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token removed. |
| account | address | The account that removed the collateral. |
| ofType | enum TokenType | The type of collateral |
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
event AssetRepaid(address account, address repaidBy, uint256 amount, uint256 debtBurned)
```

Emitted when borrowed assets are repaid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that repaid assets. |
| repaidBy | address | The account doing the repayment. This is the same as `account` in normal repayment with `putAmount` or `putShares`. In case of liquidation, this is the address of the liquidator. |
| amount | uint256 | The amount of assets repaid. |
| debtBurned | uint256 | The amount of debt token burned. |

### InterestAccrued

```solidity
event InterestAccrued(address caller, uint256 interest, uint256 totalDebt, uint256 totalAssets)
```

Emitted when interest is accrued

_called on all state changing functions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | indexed param of the caller of the action that triggered interest accrual. |
| interest | uint256 | The amount of interest accrued. |
| totalDebt | uint256 | The total amount debt pending. |
| totalAssets | uint256 | The total amount of assets including interest. |

### MintToReserve

```solidity
event MintToReserve(address caller, uint256 shares, uint256 amount)
```

Emitted when pool share tokens are minted to reserve to cover fees.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| caller | address | Caller of function that triggered event. |
| shares | uint256 | The amount of shares to mint. |
| amount | uint256 | The corresponding amount of asset for shares minted. |

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

### StakingPoolSet

```solidity
event StakingPoolSet(address pool, address caller)
```

Emitted when the staking pool for this lending pool is set

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool address. |
| caller | address | The account that set the gauge. |

### SupplyCapSet

```solidity
event SupplyCapSet(uint256 cap, address caller)
```

Emitted when the supply cap is set.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| cap | uint256 | The new supply cap. |
| caller | address | The account that set the gauge. |

### CollateralParamsSet

```solidity
event CollateralParamsSet(address token, uint256 ltv, uint256 lltv, uint256 liqPenalty, uint256 liqBonus)
```

Explain to an end user what this does

_Explain to a developer any extra details_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address |  |
| ltv | uint256 | Max loan to value. |
| lltv | uint256 | Max liquidation loan to value. |
| liqPenalty | uint256 | Liquidation penalty (goes to reserve). |
| liqBonus | uint256 | Liquidation bonus (goes to liquidator). |

### PositionLiquidated

```solidity
event PositionLiquidated(address account, address liquidator, address collateral, uint256 repayAmount)
```

Emitted when a position is successfully liquidated.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account being liquidated. |
| liquidator | address | The caller of the function. |
| collateral | address | The collateral token to liquidate. |
| repayAmount | uint256 | The amount of debt being repaid by the liquidator. |

### PoolState

```solidity
event PoolState(address pool, address caller, uint256 timestamp, uint256 supplied, uint256 borrowed, uint256 supplyRate, uint256 borrowRate)
```

Emitted any time the pool state changes

_Pool state changes on supply, withdraw, take or put. 
Also called from the `updatePoolState()` function._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool address emitting this event. This is indexed. |
| caller | address |  |
| timestamp | uint256 | The timestamp of the event. This is indexed. |
| supplied | uint256 | The total amount supplied to the pool. |
| borrowed | uint256 | The total amount borrowed from the pool. |
| supplyRate | uint256 | The base supply APY. |
| borrowRate | uint256 | The base borrow APR. |

### CollaterallizeAsset

```solidity
event CollaterallizeAsset(address account, bool useAsCollateral)
```

### CallbackApproved

```solidity
event CallbackApproved(address callback, bool isApproved)
```

_Emitted when `flashLiquidateWhitelist` is updated_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| callback | address | The address to whitelist or not |
| isApproved | bool | true of false |

### CheddaPool_CollateralNotAllowed

```solidity
error CheddaPool_CollateralNotAllowed(address token)
```

_Thrown when a caller tries to deposit a token for collateral that is not allowed_

### CheddaPool_CollateralAlreadyAdded

```solidity
error CheddaPool_CollateralAlreadyAdded(address token)
```

_Thrown when adding collateral that has already been added during initialization._

### CheddaPool_ZeroAmount

```solidity
error CheddaPool_ZeroAmount()
```

_Thrown when a caller tries to supply/deposit 0 amount of asset/collateral._

### CheddaPool_SupplyCapExceeded

```solidity
error CheddaPool_SupplyCapExceeded(uint256 cap, uint256 supplied)
```

_Thrown when the supply cap is exceeded._

### CheddaPool_InsufficientCollateral

```solidity
error CheddaPool_InsufficientCollateral(address account, address token, uint256 amountRequested, uint256 amountDeposited)
```

_Thrown when a caller tries to withdraw more collateral than they have deposited._

### CheddaPool_AccountNotCollateralized

```solidity
error CheddaPool_AccountNotCollateralized(address account)
```

_Thrown when the account does not have sufficient collateral._

### CheddaPool_AccountSolvent

```solidity
error CheddaPool_AccountSolvent(address account, uint256 health)
```

_Thrown when attempting to liquidate a solvent account._

### CheddaPool_InsufficientAssetBalance

```solidity
error CheddaPool_InsufficientAssetBalance(uint256 available, uint256 requested)
```

_Thrown when a caller tries withdraw more asset than supplied._

### CheddaPool_Overpayment

```solidity
error CheddaPool_Overpayment()
```

_Thrown when a caller tries to repay more debt than they owe._

### CheddaPool_AssetMustBeSupplied

```solidity
error CheddaPool_AssetMustBeSupplied()
```

_Thrown when a caller tries to deposit the asset token as collateral._

### CheddaPool_AsssetMustBeWithdrawn

```solidity
error CheddaPool_AsssetMustBeWithdrawn()
```

_Thrown when a caller tries to remove asset token from collateral. `withdraw` must be used instead._

### CheddaPool_ZeroShares

```solidity
error CheddaPool_ZeroShares()
```

_Thrown when withdrawing or depositing zero shares_

### CheddaPool_BadPrice

```solidity
error CheddaPool_BadPrice(address asset, uint256 price)
```

_Thrown if the asset price is invalid._

### CheddaPool_StalePrice

```solidity
error CheddaPool_StalePrice(address asset, uint256 lastUpdated)
```

_Thrown if the asset price is stale._

### CheddaPool_InvalidLiquidation

```solidity
error CheddaPool_InvalidLiquidation()
```

Thrown in an invalid liquidation call.

### CheddaPool_UnsupportedCollateral

```solidity
error CheddaPool_UnsupportedCollateral(address collateralToken)
```

Thrown when trying to calculate the value of unsupported collateral token

### CheddaPool_InvalidCollateralParams

```solidity
error CheddaPool_InvalidCollateralParams()
```

_Thrown when setting invalid collateral params_

### CheddaPool_CallbackNotApproved

```solidity
error CheddaPool_CallbackNotApproved(address callback)
```

_Thrown when a non approved callback is used in `flashLiquidate()`_

### supplied

```solidity
uint256 supplied
```

state vars

### totalReserveShares

```solidity
uint256 totalReserveShares
```

_lifetime shares minted to reserve_

### characterization

```solidity
string characterization
```

_display name of thi spool_

### debtToken

```solidity
contract DebtToken debtToken
```

Debt and interest

### registry

```solidity
contract IAddressRegistry registry
```

### priceFeed

```solidity
contract IPriceFeed priceFeed
```

### interestRatesModel

```solidity
contract IInterestRateModel interestRatesModel
```

### interestRates

```solidity
struct InterestRates interestRates
```

### gauge

```solidity
contract ILockingGauge gauge
```

### stakingPool

```solidity
contract IStakingPool stakingPool
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

### assetCollateralized

```solidity
mapping(address => bool) assetCollateralized
```

### collateralParams

```solidity
mapping(address => struct CollateralParams) collateralParams
```

### accountCollateralDeposited

```solidity
mapping(address => mapping(address => struct CollateralDeposit)) accountCollateralDeposited
```

### tokenCollateralDeposited

```solidity
mapping(address => uint256) tokenCollateralDeposited
```

### approvedCallbacks

```solidity
mapping(address => bool) approvedCallbacks
```

_addresses approved to be used as callbacks_

### maxAccountHealth

```solidity
uint256 maxAccountHealth
```

_The max value for account health. This is returned if user has no debt._

### supplyCap

```solidity
uint256 supplyCap
```

_Pool asset supply cap_

### reserveFactor

```solidity
uint256 reserveFactor
```

_Percentage of interest that goes to reserve. 1e18 = 100%_

### stalePriceThreshold

```solidity
uint256 stalePriceThreshold
```

### reserve

```solidity
address reserve
```

_address to receive reserve funds_

### icmAccountCollateral

```solidity
mapping(address => address) icmAccountCollateral
```

### InitParams

initialization

```solidity
struct InitParams {
  string name;
  address asset;
  address priceFeed;
  address interestRatesModel;
  address owner;
  address registry;
  address reserve;
  uint256 reserveFactor;
  uint256 initialSupplyCap;
  uint256 stalePriceThreshold;
  struct CollateralInfoInit[] collaterals;
}
```

### constructor

```solidity
constructor(struct LendingPool.InitParams initParams) public
```

### setGauge

```solidity
function setGauge(address _gauge) external
```

Set the rewards gauge for this pool.

_Can only be called by contract owner
Emits GaugeSet(gauge, caller)._

### setStakingPool

```solidity
function setStakingPool(address sPool) external
```

Set the staking pool for this pool.

_Can only be called by contract owner
Emits StakingPoolSet(sPool, caller)._

### setSupplyCap

```solidity
function setSupplyCap(uint256 _supplyCap) external
```

Sets the supply cap in this pool.

_This is the maximum amount that can be supplied in this pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _supplyCap | uint256 | The new supply cap |

### setCallbackApproved

```solidity
function setCallbackApproved(address callback, bool isApproved) external
```

approves or disapproves a callback address

### setCollateralParams

```solidity
function setCollateralParams(address token, struct CollateralParams params) external
```

### supply

```solidity
function supply(uint256 amount, address receiver, bool useAsCollateral) external returns (uint256 shares)
```

Supplies assets to pool

_if `useAsCollateral` is true, and `receiver != msg.sender`, collateral is added to
`receiver`'s collateral balance._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to supply |
| receiver | address | The account to mint share tokens to |
| useAsCollateral | bool | Whethe this deposit should be marked as collateral |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The amount of shares minted. |

### withdraw

```solidity
function withdraw(uint256 assetAmount, address receiver, address owner) public returns (uint256 shares)
```

Withdraws a specified amount of assets from pool

_If user has added this asset as collateral a collateral amount will be removed.
if `owner != msg.sender` there must be an existing approval >= assetAmount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| assetAmount | uint256 | The amount to withdraw |
| receiver | address | The account to receive withdrawn assets |
| owner | address | The account to withdraw assets from. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | The amount of shares burned by withdrawal. |

### redeem

```solidity
function redeem(uint256 shares, address receiver, address owner) public returns (uint256 assetAmount)
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
| assetAmount | uint256 | The amount of assets repaid. |

### take

```solidity
function take(uint256 amount) external returns (uint256 debtCreated)
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
| debtCreated | uint256 | The amount of debt token minted. |

### putAmount

```solidity
function putAmount(uint256 amount) external returns (uint256 debtBurned)
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
| debtBurned | uint256 | The amount of debt shares burned by this repayment. |

### putShares

```solidity
function putShares(uint256 shares) external returns (uint256 amountRepaid)
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
| amountRepaid | uint256 | the amount repaid. |

### collateralize

```solidity
function collateralize(bool useAsCollateral) external
```

Managing collateral logic

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

### LiquidateParams

Struct passed in to liquidation functions.

_Contains parameters forliquidation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct LiquidateParams {
  address borrower;
  address receiver;
  address collateral;
  uint256 repayAmount;
}
```

### batchLiquidate

```solidity
function batchLiquidate(struct LendingPool.LiquidateParams[] params) external returns (uint256[])
```

Allows an account to liquidate a borrower's position if their health factor falls below 1.0e18.

_Throws the `CheddaPool_InvalidLiquidation` error if there is a mismatch in length of any of
`borrowers`, `collateralTokens`, `repayAmounts`.
Throws `CheddaPool_InvalidLiquidation` error if health of a borrower after liquidation is not
greater than the health before liquidation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct LendingPool.LiquidateParams[] | Array of `LiquidateParams` objects specifying parameters for liquidations. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | collateralAmounts The amounts of collateral removed. |

### flashLiquidate

```solidity
function flashLiquidate(struct LendingPool.LiquidateParams params, address callback, bytes data) external returns (uint256)
```

Explain to an end user what this does

_Explain to a developer any extra details_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct LendingPool.LiquidateParams | Array of `LiquidateParams` objects specifying parameters for liquidations. |
| callback | address |  |
| data | bytes |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | totalCollateralAmount The amount of collateral the liquidator received. |

### getPrice

```solidity
function getPrice(address asset, bool checkAge) public view returns (uint256)
```

View functions
Reads the price of an asset from the oracle

_Explain to a developer any extra details_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| asset | address | The asset to return price for |
| checkAge | bool | Check if the price has been updated recently. Revert if `checkAge` is true and price is stale. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The price of the asset. |

### totalAccountCollateralValue

```solidity
function totalAccountCollateralValue(address account, enum AccountValue valueType) public view returns (uint256 accountValue)
```

Returns the total value of an account including asset and collateral.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to get collateral value for. |
| valueType | enum AccountValue | Determines how the value is calculated. This is of enum `AccountValue`. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| accountValue | uint256 | The value of collateral deposited by account. |

### accountCollateralAmount

```solidity
function accountCollateralAmount(address account, address collateral) public view returns (uint256 collateralAmount)
```

Returns the amount of a given token an account has deposited as collateral

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check collateral for |
| collateral | address | The collateral to check |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| collateralAmount | uint256 | The amount of `collateral` token `account` has deposited. |

### assetsBorrowed

```solidity
function assetsBorrowed(address account) public view returns (uint256)
```

Returns the amount of asset an account has borrowed, including any accrued interest.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account to check for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | amount The amount of account borrowed by `account`. |

### accountHealth

```solidity
function accountHealth(address account) public view returns (uint256 health)
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
| health | uint256 | The health ration of the account, to 1e18. i.e 1e18 = 1.0 health. |

### collaterals

```solidity
function collaterals() external view returns (address[])
```

### calculateCollateralAmount

```solidity
function calculateCollateralAmount(uint256 assetAmount, address collateralToken, bool useLTV) public view returns (uint256 collateralAmount)
```

### tokenMarketValue

```solidity
function tokenMarketValue(address token, uint256 amount) public view returns (uint256)
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

### tokenLoanValue

```solidity
function tokenLoanValue(address token, uint256 amount) public view returns (uint256)
```

Returns the value as collateral for a given amount of token

_This takes into account the loan to value (LTV) ratio._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token to return value for. |
| amount | uint256 | The amount of token to calculate the value of. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | value The collateral value of `amount` of `token`. |

### tokenLiquidationValue

```solidity
function tokenLiquidationValue(address token, uint256 amount) public view returns (uint256)
```

Returns the value as collateral for a given amount of token

_This takes into account the lltv._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token to return value for. |
| amount | uint256 | The amount of token to calculate the value of. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | value The collateral value of `amount` of `token`. |

### collateralInfo

```solidity
function collateralInfo(address token) external view returns (struct CollateralParams)
```

Returns the collateral configuration for a given token;

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token to return collateral info for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct CollateralParams | The `CollateralParams` for requested token. |

### updatePoolState

```solidity
function updatePoolState() external
```

_take a snapshot of the current pool state._

### isSolvent

```solidity
function isSolvent(address account) external view returns (bool)
```

Checks if account is solvent.
In simple terms, an account is solvent if collateralMarketValue * liquidation threshold > debt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | account to check for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | If the account is solvent. |

### isCollateralized

```solidity
function isCollateralized(address account) public view returns (bool)
```

Checks if account has enough collateral after currnet operation completes.

_In simple terms, an account is collateralized if collateralMarketValue * ltv > debt._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | account to check for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | If the account is collateralized. |

### accrueInterest

```solidity
function accrueInterest() public
```

### poolAsset

```solidity
function poolAsset() external view returns (contract ERC20)
```

Returns the asset that can be borrowed from this pool

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ERC20 | asset The pool asset |

### assetBalance

```solidity
function assetBalance(address account) public view returns (uint256)
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

### transfer

```solidity
function transfer(address to, uint256 amount) public returns (bool success)
```

Transfer tokens from caller to another address.

_Overrides ERC-20 transfer to add health checks after transfers_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | address to send to |
| amount | uint256 | amount to send |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| success | bool | True if transfer is successful, false otherwise. |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) public returns (bool success)
```

Transfer tokens from a given address to another.

_Overrides ERC-20 transferFrom to add health checks after transfers. 
Caller must have an allowance to transfer from `from` address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | address to send from |
| to | address | address to send to |
| amount | uint256 | amount to send |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| success | bool | True if transfer is successful, false otherwise. |

### available

```solidity
function available() public view returns (uint256 assetAmount)
```

The assets available to be borrowed from pool.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| assetAmount | uint256 | The amount of asset available in pool. |

### borrowed

```solidity
function borrowed() public view returns (uint256 assetAmount)
```

The assets borrowed from pool.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| assetAmount | uint256 | The amount of asset borrowed from pool, including accrued interest. |

### tvl

```solidity
function tvl(bool countBorrows) external view returns (uint256 totalValue)
```

The total value locked in this pool.

_TVL is calculated as assets supplied + collateral deposited._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| countBorrows | bool | Flag indicating if the borrows should be included in TVL calculation. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| totalValue | uint256 | The total value locked in pool. |

### baseSupplyAPY

```solidity
function baseSupplyAPY() external view returns (uint256 apy)
```

Returns the base supply APY.

_This is the interest earned on supplied assets._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| apy | uint256 | The interest earned on supplied assets. |

### baseBorrowAPY

```solidity
function baseBorrowAPY() external view returns (uint256 apy)
```

Returns the base borrow APY.

_This is the interest paid on borrowed assets._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| apy | uint256 | The interest paid on borrowed assets. |

### utilization

```solidity
function utilization() public view returns (uint256 u)
```

The pool asset utilization

_This is the amount of asset borrowed divided by assets supplied._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| u | uint256 | The pool asset utilization. |

### beforeWithdraw

```solidity
function beforeWithdraw(uint256 assets, uint256) internal
```

deposit/withdraw hooks

### afterDeposit

```solidity
function afterDeposit(uint256 assets, uint256) internal
```

### version

```solidity
function version() external pure returns (uint16)
```

Returns the version of the pool

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint16 | The version |


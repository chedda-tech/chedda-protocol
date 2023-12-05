# Solidity API

## ILiquidityGauge

### claim

```solidity
function claim() external
```

### rollover

```solidity
function rollover(uint256 balance, uint256 weight, uint256 rate) external
```

### setRewardRate

```solidity
function setRewardRate(uint256 rate) external
```

### recordVote

```solidity
function recordVote(address account) external
```

### rewardToken

```solidity
function rewardToken() external view returns (address)
```

### rewardRate

```solidity
function rewardRate() external view returns (uint256)
```

## LendingPoolLens

Provides utility functions to view the state of LendingPools

### PoolStats

```solidity
struct PoolStats {
  address pool;
  address asset;
  string characterization;
  uint256 supplied;
  uint256 suppliedValue;
  uint256 borrowed;
  uint256 borrowedValue;
  uint256 baseSupplyAPY;
  uint256 maxSupplyAPY;
  uint256 baseBorrowAPY;
  uint256 maxBorrowAPY;
  uint256 utilization;
  uint256 feesPaid;
  uint256 tvl;
  address[] collaterals;
}
```

### AggregateStats

```solidity
struct AggregateStats {
  uint256 totalSuppliedValue;
  uint256 totalBorrowedValue;
  uint256 totalAvailableValue;
  uint256 totalFeesPaid;
  uint256 numberOfVaults;
  uint256 tvl;
}
```

### PoolCollateralInfo

```solidity
struct PoolCollateralInfo {
  address collateral;
  uint256 amountDeposited;
  uint256 value;
  uint256 collateralFactor;
}
```

### LendingPoolInfo

```solidity
struct LendingPoolInfo {
  uint256 assetOraclePrice;
  uint256 interestFeePercentage;
  uint256 liquidationThreshold;
  uint256 liquidationPenalty;
}
```

### AccountCollateralDeposited

```solidity
struct AccountCollateralDeposited {
  address token;
  uint256 amount;
  uint256 value;
  uint256[] tokenIds;
}
```

### AccountInfo

```solidity
struct AccountInfo {
  uint256 supplied;
  uint256 borrowed;
  uint256 healthFactor;
  uint256 totalCollateralValue;
  struct LendingPoolLens.AccountCollateralDeposited[] collateralDeposited;
}
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
constructor(address _owner) public
```

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

### getAggregateStats

```solidity
function getAggregateStats() external view returns (struct LendingPoolLens.AggregateStats)
```

Explain to an end user what this does

_Explain to a developer any extra details_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.AggregateStats | aggregateStats The aggregated stats of the all registred pools |

### getPoolStatsList

```solidity
function getPoolStatsList(address[] pools) external view returns (struct LendingPoolLens.PoolStats[])
```

Returns various metrics of specified pools.

_Returns an array of `PoolStats` objects.
Reverts with NotRegistered(pool) error if a pool in the list is not registered._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pools | address[] | The list of pools to return stats for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.PoolStats[] | poolStats An array of `PoolStats` objects, containing the stats for specified pools. |

### getPoolStats

```solidity
function getPoolStats(address poolAddress) public view returns (struct LendingPoolLens.PoolStats)
```

Regturns the metrics of a specified pool.

_Reverts with `NotRegistered(address) error if the pool address is not registered._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The address of the pool to return stats for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.PoolStats | poolStats The `PoolStats` object containing the stats for specified pool. |

### getPoolAccountInfo

```solidity
function getPoolAccountInfo(address poolAddress, address account) external view returns (struct LendingPoolLens.AccountInfo)
```

Returns information about a given account in a specified pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The pool to return account info for. |
| account | address | The account to return info about. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.AccountInfo | info An `AccountInfo` obect about `account` position in the pool. |

### getPoolCollateral

```solidity
function getPoolCollateral(address poolAddress) external view returns (struct LendingPoolLens.PoolCollateralInfo[])
```

Returns information about colalteral in the pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The pool to return collateral info for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LendingPoolLens.PoolCollateralInfo[] | info The `PoolCollateralInfo` about collateral in the specified pool. |

## IPriceFeed

### decimals

```solidity
function decimals() external view returns (uint8)
```

_The decimals of values returned by this feed._

### token

```solidity
function token() external view returns (address)
```

The token this feed returns a price for.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address token addrss. |

### readPrice

```solidity
function readPrice(address token, uint256 tokenID) external view returns (int256 price)
```

Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
tokenID parameter is for forwards compatibility.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | address of the asset's token. |
| tokenID | uint256 | The number of tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| price | int256 | the price of the asset |

## InterestRates

```solidity
struct InterestRates {
  uint256 supplyRate;
  uint256 borrowRate;
}
```

## IInterestRateModel

### calculateInterestRate

```solidity
function calculateInterestRate(uint256 utilization) external view returns (uint256)
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256 liquidityAdded, uint256 liquidityTaken) external view returns (struct InterestRates)
```

## ILendingPool

### poolAsset

```solidity
function poolAsset() external view returns (contract ERC20)
```

### debtToken

```solidity
function debtToken() external view returns (contract DebtToken)
```

### characterization

```solidity
function characterization() external view returns (string)
```

### supplied

```solidity
function supplied() external view returns (uint256)
```

### borrowed

```solidity
function borrowed() external view returns (uint256)
```

### available

```solidity
function available() external view returns (uint256)
```

### baseSupplyAPY

```solidity
function baseSupplyAPY() external view returns (uint256)
```

### baseBorrowAPY

```solidity
function baseBorrowAPY() external view returns (uint256)
```

### utilization

```solidity
function utilization() external view returns (uint256)
```

### tvl

```solidity
function tvl() external view returns (uint256)
```

### feesPaid

```solidity
function feesPaid() external view returns (uint256)
```

### priceFeed

```solidity
function priceFeed() external view returns (contract IPriceFeed)
```

### gauge

```solidity
function gauge() external view returns (contract ILiquidityGauge)
```

### interestRateModel

```solidity
function interestRateModel() external view returns (contract IInterestRateModel)
```

### collaterals

```solidity
function collaterals() external view returns (address[])
```

### collateralFactor

```solidity
function collateralFactor(address) external view returns (uint256)
```

### tokenCollateralDeposited

```solidity
function tokenCollateralDeposited(address) external view returns (uint256)
```

### accountHealth

```solidity
function accountHealth(address account) external view returns (uint256)
```

### assetBalance

```solidity
function assetBalance(address account) external view returns (uint256)
```

### totalAccountCollateralValue

```solidity
function totalAccountCollateralValue(address account) external view returns (uint256)
```

### accountCollateralAmount

```solidity
function accountCollateralAmount(address account, address collateral) external view returns (uint256)
```

### getTokenCollateralValue

```solidity
function getTokenCollateralValue(address token, uint256 amount) external view returns (uint256)
```

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

_Thrown when an invalid price is encountered when reading the asset or collateral price._

### CheddaPool_CollateralNotAllowed

```solidity
error CheddaPool_CollateralNotAllowed(address token)
```

_Thrown when a caller tries to deposit a token for collateral that is not allowed_

### CheddaPool_WrongCollateralType

```solidity
error CheddaPool_WrongCollateralType(address token)
```

_Thrown when depositing an ERC-20 as ERC-721 or vice veresa._

### CheddaPool_ZeroAmount

```solidity
error CheddaPool_ZeroAmount()
```

_Thrown when a caller tries to supply/deposit 0 amount of asset/collateral._

### CheddaPool_InsufficientCollateral

```solidity
error CheddaPool_InsufficientCollateral(address account, address token, uint256 amountRequested, uint256 amountDeposited)
```

_Thrown when a caller tries to withdraw more collateral than they have deposited._

### CheddaPool_AccountInsolvent

```solidity
error CheddaPool_AccountInsolvent(address account, uint256 health)
```

_Thrown when a withdrawing an amount of collateral would put the account in an insolvent state._

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

### CheddaPool_ZeroShsares

```solidity
error CheddaPool_ZeroShsares()
```

_Thrown when withdrawing or depositing zero shares_

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

### setGauge

```solidity
function setGauge(address _gauge) external
```

Set the rewards gauge for this pool.

_Can only be called by contract owner
Emits GaugeSet(gauge, caller)._

### supply

```solidity
function supply(uint256 amount, address receiver, bool useAsCollateral) external returns (uint256)
```

Supplies assets to pool

_if `useAsCollateral` is true, and `receiver != msg.sender`, collateral is added to
`msg.sender`'s collateral balance._

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

### _normalizeDecimals

```solidity
function _normalizeDecimals(uint256 value, uint8 inDecimals, uint8 outDecimals) internal pure returns (uint256)
```

_convert from `inDecimals` to `outDecimals`._

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

### beforeWithdraw

```solidity
function beforeWithdraw(uint256 assets, uint256 shares) internal
```

deposit/withdraw hooks

### afterDeposit

```solidity
function afterDeposit(uint256 assets, uint256 shares) internal
```

## LinearInterestRateModel

### owner

```solidity
address owner
```

### baseInterestRate

```solidity
uint256 baseInterestRate
```

### steeperSlopeInterestRate

```solidity
uint256 steeperSlopeInterestRate
```

### targetUtilization

```solidity
uint256 targetUtilization
```

### constructor

```solidity
constructor(uint256 _baseInterestRate, uint256 _steeperSlopeInterestRate, uint256 _targetUtilization) public
```

### calculateInterestRate

```solidity
function calculateInterestRate(uint256 utilization) public view returns (uint256)
```

### updateInterestRateParameters

```solidity
function updateInterestRateParameters(uint256 _baseInterestRate, uint256 _steeperSlopeInterestRate, uint256 _targetUtilization) public
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256, uint256) external pure returns (struct InterestRates)
```

## SimpleInterestRateModel

### linearInterestRate

```solidity
uint256 linearInterestRate
```

### exponentialInterestRate

```solidity
uint256 exponentialInterestRate
```

### targetUtilization

```solidity
uint256 targetUtilization
```

### constructor

```solidity
constructor(uint256 _linearRate, uint256 _exponentialRate, uint256 _targetUtilization) public
```

### calculateInterestRate

```solidity
function calculateInterestRate(uint256 currentUtilization) public view returns (uint256)
```

### updateLinearInterestRate

```solidity
function updateLinearInterestRate(uint256 newLinearRate) public
```

### updateExponentialInterestRate

```solidity
function updateExponentialInterestRate(uint256 newExponentialRate) public
```

### updateTargetUtilization

```solidity
function updateTargetUtilization(uint256 newTargetUtilization) public
```

### calculateInterestRates

```solidity
function calculateInterestRates(uint256, uint256) external pure returns (struct InterestRates)
```

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

### totalDebt

```solidity
function totalDebt() external view returns (uint256 borrowed)
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

## IRebaseToken

Interface representing a rebase token

### rebase

```solidity
function rebase() external returns (uint256)
```

Called to perform a rebase on the token

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


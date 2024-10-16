# Solidity API

## TokenType

_The type of the collateral.
Options are Invalid, ERC20, ERC721 and ERC1155._

```solidity
enum TokenType {
  Invalid,
  ERC20,
  ERC721,
  ERC155
}
```

## CollateralInfo

Holds information about the type of collateral held in vault.

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct CollateralInfo {
  uint256 ltv;
  uint256 liqThreshold;
  uint256 liqPenalty;
}
```

## CollateralInfoInit

```solidity
struct CollateralInfoInit {
  address token;
  struct CollateralInfo info;
}
```

## CollateralDeposit

_Information about collateral deposited to the pool._

```solidity
struct CollateralDeposit {
  address token;
  enum TokenType tokenType;
  uint256 amount;
  uint256[] tokenIds;
}
```

## AccountCollateralValue

_The value of a collateral token deposited by an account._

```solidity
struct AccountCollateralValue {
  address token;
  uint256 amount;
  int256 value;
}
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

### supplyCap

```solidity
function supplyCap() external view returns (uint256)
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

### totalReserveShares

```solidity
function totalReserveShares() external view returns (uint256)
```

### priceFeed

```solidity
function priceFeed() external view returns (contract IPriceFeed)
```

### interestRatesModel

```solidity
function interestRatesModel() external view returns (contract IInterestRateModel)
```

### collaterals

```solidity
function collaterals() external view returns (address[])
```

### collateralInfo

```solidity
function collateralInfo(address) external view returns (struct CollateralInfo)
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

### accountAssetsBorrowed

```solidity
function accountAssetsBorrowed(address account) external view returns (uint256)
```

### totalAccountCollateralValue

```solidity
function totalAccountCollateralValue(address account) external view returns (uint256)
```

### accountCollateralAmount

```solidity
function accountCollateralAmount(address account, address collateral) external view returns (uint256)
```

### tokenMaxLoanValue

```solidity
function tokenMaxLoanValue(address token, uint256 amount) external view returns (uint256)
```

### getTokenMarketValue

```solidity
function getTokenMarketValue(address token, uint256 amount) external view returns (uint256)
```

### recapitalize

```solidity
function recapitalize() external returns (uint256)
```


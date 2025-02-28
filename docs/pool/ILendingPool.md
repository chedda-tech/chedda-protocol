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

## AccountValue

```solidity
enum AccountValue {
  Market,
  Loan,
  Liquidation
}
```

## CollateralParams

Holds information about the type of collateral held in vault.
ltv + liqPenalty + liqBonus must be < lltv

### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct CollateralParams {
  uint256 ltv;
  uint256 lltv;
  uint256 liqPenalty;
  uint256 liqBonus;
}
```

## CollateralInfoInit

```solidity
struct CollateralInfoInit {
  address token;
  struct CollateralParams info;
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
function tvl(bool) external view returns (uint256)
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
function collateralInfo(address) external view returns (struct CollateralParams)
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

### assetsBorrowed

```solidity
function assetsBorrowed(address account) external view returns (uint256)
```

### accountCollateralAmount

```solidity
function accountCollateralAmount(address account, address collateral) external view returns (uint256)
```

### tokenMarketValue

```solidity
function tokenMarketValue(address token, uint256 amount) external view returns (uint256)
```

### tokenLoanValue

```solidity
function tokenLoanValue(address token, uint256 amount) external view returns (uint256)
```

### tokenLiquidationValue

```solidity
function tokenLiquidationValue(address token, uint256 amount) external view returns (uint256)
```

### totalAccountCollateralValue

```solidity
function totalAccountCollateralValue(address account, enum AccountValue valueType) external view returns (uint256)
```


# Solidity API

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

### feesPaid

```solidity
function feesPaid() external view returns (uint256)
```

### priceFeed

```solidity
function priceFeed() external view returns (contract IPriceFeed)
```

### interestRatesModel

```solidity
function interestRatesModel() external view returns (contract IInterestRatesModel)
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

### getTokenCollateralValue

```solidity
function getTokenCollateralValue(address token, uint256 amount) external view returns (uint256)
```

### getTokenMarketValue

```solidity
function getTokenMarketValue(address token, uint256 amount) external view returns (uint256)
```


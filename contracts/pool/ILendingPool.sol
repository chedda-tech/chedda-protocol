// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IInterestRateModel } from "../interestrates/IInterestRateModel.sol";
import { IPriceFeed } from "../oracle/IPriceFeed.sol";
import { DebtToken } from "../tokens/DebtToken.sol";

 /// @dev The type of the collateral.
/// Options are Invalid, ERC20, ERC721 and ERC1155.
enum TokenType {
    Invalid,
    ERC20,
    ERC721,
    ERC155
}

enum AccountValue {
    Market, 
    Loan, 
    Liquidation
}

/// @notice Holds information about the type of collateral held in vault.
/// ltv + liqPenalty + liqBonus must be < lltv
/// @param ltv The max loan to value ratio for this collateral. 1e18 = 100%
/// @param lltv The liquidation ltv. Used in calculation of health factor.
/// @param liqPenalty The liquidation penalty that goes to reserve.
/// @param liqBonus The discount rate liquidators get for this collateral
struct CollateralParams {
    uint256 ltv;
    uint256 lltv;
    uint256 liqPenalty;
    uint256 liqBonus;
}

struct CollateralInfoInit {
    address token;
    CollateralParams info;
}

/// @dev Information about collateral deposited to the pool.
struct CollateralDeposit {
    address token;
    TokenType tokenType;
    uint256 amount;
    uint256[] tokenIds;
}

/// @dev The value of a collateral token deposited by an account.
struct AccountCollateralValue {
    address token;
    uint256 amount;
    int256 value;
}

interface ILendingPool {
    function poolAsset() external view returns (ERC20);
    function debtToken() external view returns (DebtToken);
    function characterization() external view returns (string memory);
    function supplyCap() external view returns (uint256);
    function supplied() external view returns (uint256);
    function borrowed() external view returns (uint256);
    function available() external view returns (uint256);
    function baseSupplyAPY() external view returns (uint256);
    function baseBorrowAPY() external view returns (uint256);
    function utilization() external view returns (uint256);
    function tvl(bool) external view returns (uint256);
    function totalReserveShares() external view returns (uint256);
    function priceFeed() external view returns (IPriceFeed);
    function interestRatesModel() external view returns (IInterestRateModel);
    function collaterals() external view returns (address [] memory);
    function collateralInfo(address) external view returns (CollateralParams memory);
    function tokenCollateralDeposited(address) external view returns (uint256);
    function accountHealth(address account) external view returns (uint256);
    function assetBalance(address account) external view returns (uint256);
    function assetsBorrowed(address account) external view returns (uint256);
    function accountCollateralAmount(address account, address collateral) external view returns (uint256);
    function tokenMarketValue(address token, uint256 amount) external view returns (uint256);
    function tokenLoanValue(address token, uint256 amount) external view returns (uint256);
    function tokenLiquidationValue(address token, uint256 amount) external view returns (uint256);
    function totalAccountCollateralValue( address account, AccountValue valueType) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IInterestRateModel } from "../interestrates/IInterestRateModel.sol";
import { ILiquidityGauge } from "../gauge/ILiquidityGauge.sol";
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

/// @notice Holds information about the type of collateral held in vault.
/// @param ltv The max loan to value ration for this collateral. 1e18 = 100%
/// @param liqThreshold The liquidation threshold
/// @param liqPenalty The liquidation penalty
struct CollateralInfo {
    uint256 ltv;
    uint256 liqThreshold;
    uint256 liqPenalty;
}

struct CollateralInfoInit {
    address token;
    CollateralInfo info;
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
    function tvl() external view returns (uint256);
    function totalReserveShares() external view returns (uint256);
    function priceFeed() external view returns (IPriceFeed);
    function interestRatesModel() external view returns (IInterestRateModel);
    function collaterals() external view returns (address [] memory);
    function collateralInfo(address) external view returns (CollateralInfo memory);
    function tokenCollateralDeposited(address) external view returns (uint256);
    function accountHealth(address account) external view returns (uint256);
    function assetBalance(address account) external view returns (uint256);
    function accountAssetsBorrowed(address account) external view returns (uint256);
    function totalAccountCollateralValue(address account) external view returns (uint256);
    function accountCollateralAmount(address account, address collateral) external view returns (uint256);
    function tokenMaxLoanValue(address token, uint256 amount) external view returns (uint256);
    function getTokenMarketValue(address token, uint256 amount) external view returns (uint256);
    function recapitalize() external returns (uint256);
}

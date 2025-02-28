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

    /// events

    /// Events

    /// @notice Emitted when collateral is added
    /// @param token The token added
    /// @param account The account that added the collateral.
    /// @param ofType The type of collateral
    /// @param amount The amount of token added as collateral
    event CollateralAdded(
        address indexed token,
        address indexed account,
        TokenType ofType,
        uint256 amount
    );

    /// @notice Emitted when collateral is removed
    /// @param token The token removed.
    /// @param account The account that removed the collateral.
    /// @param ofType The type of collateral
    /// @param amount The amount of token removed as collateral
    event CollateralRemoved(
        address indexed token,
        address indexed account,
        TokenType ofType,
        uint256 amount
    );

    /// @notice Emitted when assets are borrowed.
    /// @param account The account that borrowed assets.
    /// @param amount The amount of assets borrowed.
    /// @param debtMinted The amount of debt token created.
    event AssetBorrowed(
        address indexed account,
        uint256 amount,
        uint256 debtMinted
    );

    /// @notice Emitted when borrowed assets are repaid.
    /// @param account The account that repaid assets.
    /// @param repaidBy The account doing the repayment. This is the same as
    /// `account` in normal repayment with `putAmount` or `putShares`.
    /// In case of liquidation, this is the address of the liquidator.
    /// @param amount The amount of assets repaid.
    /// @param debtBurned The amount of debt token burned.
    event AssetRepaid(
        address indexed account,
        address indexed repaidBy,
        uint256 amount,
        uint256 debtBurned
    );

    /// @notice Emitted when interest is accrued
    /// @dev called on all state changing functions.
    /// @param caller indexed param of the caller of the action that triggered interest accrual.
    /// @param interest The amount of interest accrued.
    /// @param totalDebt The total amount debt pending.
    /// @param totalAssets The total amount of assets including interest.
    event InterestAccrued(
        address indexed caller,
        uint256 interest,
        uint256 totalDebt,
        uint256 totalAssets
    );

    /// @notice Emitted when pool share tokens are minted to reserve to cover fees.
    /// @param caller Caller of function that triggered event.
    /// @param shares The amount of shares to mint.
    /// @param amount The corresponding amount of asset for shares minted.
    event MintToReserve(address indexed caller, uint256 shares, uint256 amount);

    /// @notice Emitted when the rewards gauge is set
    /// @param gauge The gauge address.
    /// @param caller The account that set the gauge.
    event GaugeSet(address indexed gauge, address indexed caller);

    /// @notice Emitted when the staking pool for this lending pool is set
    /// @param pool The pool address.
    /// @param caller The account that set the gauge.
    event StakingPoolSet(address indexed pool, address indexed caller);

    /// @notice Emitted when the supply cap is set.
    /// @param cap The new supply cap.
    /// @param caller The account that set the gauge.
    event SupplyCapSet(uint256 cap, address indexed caller);

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param ltv Max loan to value.
    /// @param lltv Max liquidation loan to value.
    /// @param liqPenalty Liquidation penalty (goes to reserve).
    /// @param liqBonus Liquidation bonus (goes to liquidator).
    event CollateralParamsSet(
        address indexed token, 
        uint256 ltv,
        uint256 lltv,
        uint256 liqPenalty,
        uint256 liqBonus
    );

    /// @notice Emitted when a position is successfully liquidated.
    /// @param account The account being liquidated.
    /// @param liquidator The caller of the function.
    /// @param collateral The collateral token to liquidate.
    /// @param repayAmount The amount of debt being repaid by the liquidator.
    event PositionLiquidated(
        address indexed account, 
        address indexed liquidator, 
        address indexed collateral, 
        uint256 repayAmount
    );

    /// @notice Emitted any time the pool state changes
    /// @dev Pool state changes on supply, withdraw, take or put. 
    /// Also called from the `updatePoolState()` function.
    /// @param pool The pool address emitting this event. This is indexed.
    /// @param timestamp The timestamp of the event. This is indexed.
    /// @param supplied The total amount supplied to the pool.
    /// @param borrowed The total amount borrowed from the pool.
    /// @param supplyRate The base supply APY.
    /// @param borrowRate The base borrow APR.
    event PoolState(
        address indexed pool,
        address indexed caller,
        uint256 indexed timestamp,
        uint256 supplied,
        uint256 borrowed,
        uint256 supplyRate,
        uint256 borrowRate
    );

    event CollaterallizeAsset(address indexed account, bool useAsCollateral);

    /// @dev Emitted when `flashLiquidateWhitelist` is updated
    /// @param callback The address to whitelist or not
    /// @param isApproved true of false
    event CallbackApproved(address indexed callback, bool isApproved);
    
    /// functions

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

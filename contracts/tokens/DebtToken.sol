// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";

/// @title DebtToken
/// @notice This is the unit of account of debt in a lending pool.
/// @dev Implements the ERC4626 interface.
contract DebtToken is ERC4626 {

    /// @notice Emitted when debt is created
    event DebtCreated(address indexed account, uint256 amount, uint256 shares);

    /// @notice Emitted when debt is repaid
    event DebtRepaid(address indexed account, uint256 amount, uint256 shares);

    /// @notice Emitted when debt accrual takes place.
    event DebtAccrued(uint256 totalDebt, uint256 interest);

    error NonTransferrable();
    error ZeroAssets();
    error ZeroShares();
    error NotVault();

    uint64 public constant STARTING_INTEREST_RATE_PER_SECOND = 317097919; // approx 1% APR
    uint64 public constant ONE_PERCENT = 1e18 / 100;
    uint64 public constant PER_SECOND = ONE_PERCENT / 365 / 86400;
    uint256 private immutable _oneAsset;

    /// @notice The vault address
    address public vault;

    /// @dev timestamp of when interest last accrued
    uint256 private _lastAccrual;

    /// @dev interest rate per second.
    /// TODO: This should be dependent on intrest rate model
    uint256 private _interestPerSecond;

    /// @dev total borrowed + accrued interest
    uint256 private _variableTotalDebt;

    modifier onlyVault() {
        if (msg.sender != vault) {
            revert NotVault();
        }
        _;
    }

    /// @notice Creates a debt token. 
    /// @param _asset the asset being borrowed.
    /// @param _vault the Chedda vault this asset is being borrowed from.
    constructor(ERC20 _asset, address _vault) 
    ERC4626(
        _asset,
        string(abi.encodePacked("CHEDDA Debt-", _asset.name())),
        string(abi.encodePacked("cd-", _asset.symbol()))
    ) 
    {
        vault = _vault;
        _oneAsset = 10**_asset.decimals(); // >77 decimals is unlikely.
    }

    /*///////////////////////////////////////////////////////////////
                    ICheddaDebtToken implementation
    //////////////////////////////////////////////////////////////*/

    /// @notice records the creation of debt. `account` borrowed `amount` of underlying token.
    /// @dev Explain to a developer any extra details
    /// @param amount The amount borrowed
    /// @param account The account doing the borrowing
    /// @return shares The number of tokens minted to track this debt + future interest payments.
    function createDebt(uint256 amount, address account) external onlyVault returns (uint256 shares) {
        // accrue must be called before anything else.
        // Check for rounding error since we round down in previewDeposit.
        shares = previewDeposit(amount); // No need to check for rounding error, previewWithdraw rounds up.
        if (shares == 0) {
            revert ZeroShares();
        }

        _variableTotalDebt += amount;
        _mint(account, shares);
        _accrue();

        emit DebtCreated(account, amount, shares);
    }

    /// @notice records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.
    /// @param shares The portion of debt to repay
    /// @param account The account repaying
    /// @return amount The amount of debt repaid
    function repayShare(uint256 shares, address account) external onlyVault returns (uint256 amount) {
        // Check for rounding error since we round down in previewRedeem.
        amount = previewRedeem(shares);
        if (amount == 0) {
            revert ZeroAssets();
        }

        _variableTotalDebt -= amount;
        _burn(account, shares);
        _accrue();

        emit DebtRepaid(account, amount, shares);
    }

    /// @notice records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.
    /// @param amount The amount to repay
    /// @param account The account repaying
    /// @return shares The shares burned by repaying this debt.
    function repayAmount(uint256 amount, address account) external onlyVault returns (uint256 shares) {
        shares = previewWithdraw(amount); // No need to check for rounding error, previewWithdraw rounds up.
        if (shares == 0) {
            revert ZeroShares();
        }

        _variableTotalDebt -= amount;
        _burn(account, shares);
        _accrue();

        emit DebtRepaid(account, amount, shares);
    }

    /// @notice Returns the amount of shares a given account has
    /// @param account The account to return the balance for
    /// @return shares The number of shares
    function accountShare(address account) external view returns (uint256) {
        return balanceOf[account];
    }

    /// @dev amount of assets owed per share
    function assetsPerShare() public view virtual returns (uint256) {
        return previewRedeem(_oneAsset);
    }

     /// @notice Returns total owed (amount borrowed + outstanding interest payments).
    /// @return totalDebt Total outstanding debt
    /// todo: change to totalDebt
    function totalAssets() public view override returns (uint256) {
        return _variableTotalDebt;
    }

    /// TODO: Change asset references besides underlying `asset` to debt.
    /// e.g totalAssets(), assetsPerShare(), 
    /// @notice Returns the total principal amount of debt tracked.
    /// @dev This does not include any future interest payments.
    /// @return borrowed Total amount of debt (principal) tracked.
    function totalBorrowed() external view returns (uint256 borrowed) {
        borrowed = totalAssets();
    }

    ///////////////////////////////////////////////////////////////////////////////////
    ///                 ERC20 overrides
    ///////////////////////////////////////////////////////////////////////////////////

    /// @dev Reverts with `NonTransferrable()` error. Debt tokens are non-transferrable
    function transfer(address, uint256) public pure override returns (bool) {
        revert NonTransferrable();
    }

    /// @dev Reverts with `NonTransferrable()` error. Debt tokens are non-transferrable
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert NonTransferrable();
    }

    /// @notice Accrues interest
    /// @dev External wrapper to internal `_accrue()` function.
    function accrue() external {
        _accrue();
    }

    function _accrue() private {
        uint256 timestamp =  block.timestamp;
         uint256 elapsedTime = timestamp - _lastAccrual;
        if (elapsedTime == 0) {
            return;
        }
        if (_interestPerSecond == 0) {
            _interestPerSecond = STARTING_INTEREST_RATE_PER_SECOND;
        } else {
            _interestPerSecond = _calculateNewBorrowRate();
        }

        _lastAccrual = timestamp;
        uint256 interest = ud(_variableTotalDebt).mul(ud(_interestPerSecond * elapsedTime)).unwrap();
        _variableTotalDebt += interest;

        emit DebtAccrued(_variableTotalDebt, interest);
    }

    function _calculateNewBorrowRate() private pure returns (uint256) {
        return PER_SECOND; // TODO: calculate from interest rate strategy
    }
}

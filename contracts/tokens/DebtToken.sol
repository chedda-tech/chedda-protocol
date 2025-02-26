// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import { ERC4626 } from "solmate/tokens/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

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
    error ZeroAddress();
    error ZeroAssets();
    error ZeroShares();
    error ZeroDebt(); 
    error NotPool();

    uint256 private immutable _oneAsset;

    /// @notice The pool address
    address public immutable pool;

    /// @dev total borrowed + accrued interest
    uint256 private _totalDebt;

    modifier onlyPool() {
        require(msg.sender == pool, NotPool());
        _;
    }

    /// @notice Creates a debt token. 
    /// @param _asset the asset being borrowed.
    /// @param _pool the Chedda pool this asset is being borrowed from.
    constructor(ERC20 _asset, address _pool) 
    ERC4626(
        _asset,
        string.concat("CHEDDA Debt-", _asset.name()),
        string.concat("cd-", _asset.symbol())
    ) 
    {
        require(_pool != address(0), ZeroAddress());
        pool = _pool;
        _oneAsset = 10**_asset.decimals(); // >77 decimals is unlikely.
    }

    /*///////////////////////////////////////////////////////////////
                    ICheddaDebtToken implementation
    //////////////////////////////////////////////////////////////*/

    /// @notice Records the creation of debt. `account` borrowed `amount` of underlying token.
    /// @param amount The amount borrowed
    /// @param account The account doing the borrowing
    /// @return shares The number of tokens minted to track this debt + future interest payments.
    function createDebt(uint256 amount, address account) external onlyPool returns (uint256 shares) {
        // accrue must be called before anything else.
        // Check for rounding error since we round down in previewDeposit.
        shares = previewDeposit(amount); // No need to check for rounding error, previewWithdraw rounds up.
        if (shares == 0) {
            revert ZeroShares();
        }
        _totalDebt += amount;
        _mint(account, shares);

        emit DebtCreated(account, amount, shares);
    }

    /// @notice records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.
    /// @param shares The portion of debt to repay
    /// @param account The account repaying
    /// @return amount The amount of debt repaid
    function repayShare(uint256 shares, address account) external onlyPool returns (uint256 amount) {
        // _accrue();
        // Check for rounding error since we round down in previewRedeem.
        amount = previewRedeem(shares);
        if (amount == 0) {
            revert ZeroAssets();
        }
        amount = (amount > _totalDebt) ? _totalDebt : amount;
        _totalDebt -= amount;
        _burn(account, shares);

        emit DebtRepaid(account, amount, shares);
    }

    /// @notice records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.
    /// @param amount The amount to repay
    /// @param account The account repaying
    /// @return shares The shares burned by repaying this debt.
    function repayAmount(uint256 amount, address account) external onlyPool returns (uint256 shares) {
        // _accrue();
        shares = previewWithdraw(amount); // No need to check for rounding error, previewWithdraw rounds up.
        if (shares == 0) {
            revert ZeroShares();
        }
        amount = (amount > _totalDebt) ? _totalDebt : amount;
        _totalDebt -= amount;
        _burn(account, shares);

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
        return _totalDebt;
    }

    /// e.g totalAssets(), assetsPerShare(), 
    /// @notice Returns the total principal amount of debt tracked.
    /// @dev This does not include any future interest payments.
    /// @return borrowed Total amount of debt (principal) tracked.
    function totalDebt() external view returns (uint256 borrowed) {
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

    function addInterest(uint256 interest) external onlyPool() {
        if (_totalDebt == 0) {
            revert ZeroDebt();
        }
        _totalDebt += interest;
        emit DebtAccrued(_totalDebt, interest);
    }
}

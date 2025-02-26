// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {ERC4626} from "solmate/tokens/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {UD60x18, ud} from "prb-math/UD60x18.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {DebtToken} from "../tokens/DebtToken.sol";
import {IInterestRateModel, InterestRates} from "../interestrates/IInterestRateModel.sol";
import {IPriceFeed} from "../oracle/IPriceFeed.sol";
import {
    ILendingPool, 
    CollateralParams, 
    CollateralInfoInit, 
    TokenType, 
    CollateralDeposit, 
    AccountCollateralValue, 
    AccountValue} from "./ILendingPool.sol";
import {MathLib} from "../library/MathLib.sol";
import {IAddressRegistry} from "../config/IAddressRegistry.sol";
import {ICheddaPool} from "../rewards/ICheddaPool.sol";
import {IStakingPool} from "../rewards/IStakingPool.sol";
import {StakingPool} from "../rewards/StakingPool.sol";
import {ILockingGauge} from "../rewards/ILockingGauge.sol";
import {CheddaLockingGauge} from "../rewards/CheddaLockingGauge.sol";
import {IFlashLiquidationCallback} from "./IFlashLiquidationCallback.sol";

/// @title LendingPool
/// @notice Implements supply and borrow functionality.
/// @dev Implements ERC4626 interface.
contract LendingPool is ERC4626, Ownable, ReentrancyGuard, ILendingPool, ICheddaPool {

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

    /// Custom errors

    /// @dev Thrown when a caller tries to deposit a token for collateral that is not allowed
    error CheddaPool_CollateralNotAllowed(address token);

    /// @dev Thrown when adding collateral that has already been added during initialization.
    error CheddaPool_CollateralAlreadyAdded(address token);

    /// @dev Thrown when a caller tries to supply/deposit 0 amount of asset/collateral.
    error CheddaPool_ZeroAmount();

    /// @dev Thrown when the supply cap is exceeded.
    error CheddaPool_SupplyCapExceeded(uint256 cap, uint256 supplied);

    /// @dev Thrown when a caller tries to withdraw more collateral than they have deposited.
    error CheddaPool_InsufficientCollateral(
        address account,
        address token,
        uint256 amountRequested,
        uint256 amountDeposited
    );

    /// @dev Thrown when the account does not have sufficient collateral.
    error CheddaPool_AccountNotCollateralized(address account);

    /// @dev Thrown when attempting to liquidate a solvent account.
    error CheddaPool_AccountSolvent(address account, uint256 health);

    /// @dev Thrown when a caller tries withdraw more asset than supplied.
    error CheddaPool_InsufficientAssetBalance(
        uint256 available,
        uint256 requested
    );

    /// @dev Thrown when a caller tries to repay more debt than they owe.
    error CheddaPool_Overpayment();

    /// @dev Thrown when a caller tries to deposit the asset token as collateral.
    error CheddaPool_AssetMustBeSupplied();

    /// @dev Thrown when a caller tries to remove asset token from collateral. `withdraw` must be used instead.
    error CheddaPool_AsssetMustBeWithdrawn();

    /// @dev Thrown when withdrawing or depositing zero shares
    error CheddaPool_ZeroShares();

    /// @dev Thrown if the asset price is invalid.
    error CheddaPool_BadPrice(address asset, uint256 price);

    /// @dev Thrown if the asset price is stale.
    error CheddaPool_StalePrice(address asset, uint256 lastUpdated);
    
    /// @notice Thrown in an invalid liquidation call.
    error CheddaPool_InvalidLiquidation();

    /// @notice Thrown when trying to calculate the value of unsupported collateral token
    error CheddaPool_UnsupportedCollateral(address collateralToken);

    /// @dev Thrown when setting invalid collateral params
    error CheddaPool_InvalidCollateralParams();

    /// @dev Thrown when a non approved callback is used in `flashLiquidate()`
    error CheddaPool_CallbackNotApproved(address callback);

    using MathLib for uint256;
    using SafeCast for int256;
    using SafeTransferLib for ERC20;

    /// state vars
    uint256 public supplied;

    /// @dev lifetime shares minted to reserve
    uint256 public totalReserveShares;

    /// @dev display name of thi spool
    string public characterization;

    /// Debt and interest
    DebtToken public immutable debtToken;
    IAddressRegistry public immutable registry;
    IPriceFeed public immutable priceFeed;
    IInterestRateModel public immutable interestRatesModel;
    InterestRates public interestRates;
    ILockingGauge public gauge;
    IStakingPool public stakingPool;

    /// Collateral

    // list of tokens that can be used as collateral
    address[] public collateralTokenList;

    // token address => is allowed
    mapping(address => bool) public collateralAllowed;

    // account => asset is used as collateral
    mapping(address => bool) public assetCollateralized;

    // Determines Loan to Value ratio for token
    // mapping(address => uint256) public collateralFactor;
    mapping(address => CollateralParams) public collateralParams;

    // account => token => amount
    mapping(address => mapping(address => CollateralDeposit))
        public accountCollateralDeposited;

    // token address => Collateral amount
    // use to be tokenCollateral
    mapping(address => uint256) public tokenCollateralDeposited;

    /// @dev addresses approved to be used as callbacks
    mapping (address => bool) public approvedCallbacks;

    /// @dev The max value for account health. This is returned if user has no debt.
    uint256 public constant maxAccountHealth = 100e18;

    /// @dev Pool asset supply cap
    uint256 public supplyCap;

    /// @dev Borrow cap per collateral token. This represents the max amount of asset
    /// that can be borrowed with a given collateral token.
    mapping(address => uint256) public borrowCap;

    /// @dev timestamp of when interest last accrued
    uint256 private _lastAccrual;

    /// @dev number of seconds in a year. Used to calculate annual interest rates
    uint256 private constant SECONDS_PER_YEAR = 365.25 days;

    /// @dev Percentage of interest that goes to reserve. 1e18 = 100%
    uint256 public reserveFactor = 0.1e18;

    uint256 public stalePriceThreshold;

    /// @dev address to receive reserve funds
    address public reserve;

    /// @notice Flag indicating if pool is operating in isolated collateral mode (ICM).
    bool public icm;

    mapping (address => address) public icmAccountCollateral;

    ///////////////////////////////////////////////////////////////////////////
    ///                         initialization
    ///////////////////////////////////////////////////////////////////////////

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
        bool icm;
        CollateralInfoInit[] collaterals;
    }

    constructor(
        InitParams memory initParams
    )
        Ownable(initParams.owner)
        ERC4626(
            ERC20(initParams.asset),
            string.concat("CHEDDA Pool ", ERC20(initParams.asset).name()),
            string.concat("ch", ERC20(initParams.asset).symbol())
        )
    {
        interestRatesModel = IInterestRateModel(initParams.interestRatesModel);
        characterization = initParams.name;
        reserveFactor = initParams.reserveFactor;
        priceFeed = IPriceFeed(initParams.priceFeed);
        registry = IAddressRegistry(initParams.registry);
        debtToken = new DebtToken(ERC20(initParams.asset), address(this));
        stakingPool = new StakingPool(initParams.registry, address(this));
        gauge = new CheddaLockingGauge(initParams.registry);
        icm = initParams.icm;
        reserve = initParams.reserve;
        stalePriceThreshold = initParams.stalePriceThreshold;
        supplyCap = initParams.initialSupplyCap;
        _initCollaterals(initParams.collaterals);
    }

    /// @dev initializes collateral tokens
    function _initCollaterals(CollateralInfoInit[] memory cInit) private {
        uint256 len = cInit.length;
        address collateral;
        for (uint256 i = 0; i < len; i++) {
            _checkCollateralParams(cInit[i].info);
            collateral = cInit[i].token;
            if (collateralAllowed[collateral]) {
                revert CheddaPool_CollateralAlreadyAdded(collateral);
            }
            collateralAllowed[collateral] = true;
            collateralParams[cInit[i].token] = cInit[i].info;
            collateralTokenList.push(collateral);
        }
    }

    /// @notice Set the rewards gauge for this pool.
    /// @dev Can only be called by contract owner
    /// Emits GaugeSet(gauge, caller).
    function setGauge(address _gauge) external onlyOwner {
        gauge = ILockingGauge(_gauge);
        emit GaugeSet(_gauge, msg.sender);
    }

    /// @notice Set the staking pool for this pool.
    /// @dev Can only be called by contract owner
    /// Emits StakingPoolSet(sPool, caller).
    function setStakingPool(address sPool) external onlyOwner {
        stakingPool = IStakingPool(sPool);
        emit StakingPoolSet(sPool, msg.sender);
    }

    /// @notice Sets the supply cap in this pool.
    /// @dev This is the maximum amount that can be supplied in this pool.
    /// @param _supplyCap The new supply cap
    function setSupplyCap(uint256 _supplyCap) external onlyOwner {
        supplyCap = _supplyCap;
        emit SupplyCapSet(_supplyCap, msg.sender);
    }

    /// @notice approves or disapproves a callback address
    function setCllbackApproved(address callback, bool isApproved) external onlyOwner {
        approvedCallbacks[callback] = isApproved;
        emit CallbackApproved(callback, isApproved);
    }

    function setCollateralParams(address token, CollateralParams memory params) external onlyOwner {
        _checkCollateralParams(params);
        collateralParams[token] = params;

        emit CollateralParamsSet(token, params.ltv, params.lltv, params.liqPenalty, params.liqBonus);
    }

    /// @dev checks collateral params
    function _checkCollateralParams(CollateralParams memory params) private pure {
        require(params.lltv < 1.0e18 && params.ltv <= params.lltv, CheddaPool_InvalidCollateralParams());
        require(params.lltv + params.liqBonus + params.liqPenalty < 1.0e18, CheddaPool_InvalidCollateralParams());
    }

    /*///////////////////////////////////////////////////////////////
                        borrow/repay logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Supplies assets to pool
    /// @param amount The amount to supply
    /// @param receiver The account to mint share tokens to
    /// @param useAsCollateral Whethe this deposit should be marked as collateral
    /// @return shares The amount of shares minted.
    /// @dev if `useAsCollateral` is true, and `receiver != msg.sender`, collateral is added to
    /// `receiver`'s collateral balance.
    function supply(
        uint256 amount,
        address receiver,
        bool useAsCollateral
    ) external nonReentrant returns (uint256 shares) {
        shares = deposit(amount, receiver);
        if (useAsCollateral) {
            if (!assetCollateralized[receiver]) {
                _collateralize(true, receiver);
            }
        }
        // zero_shares handled in ERC-4626
        _updatePoolState();
    }

    /// @notice Withdraws a specified amount of assets from pool
    /// @dev If user has added this asset as collateral a collateral amount will be removed.
    /// if `owner != msg.sender` there must be an existing approval >= assetAmount
    /// @param assetAmount The amount to withdraw
    /// @param receiver The account to receive withdrawn assets
    /// @param owner The account to withdraw assets from.
    /// @return shares The amount of shares burned by withdrawal.
    function withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 shares) {
        shares = super.withdraw(assetAmount, receiver, owner);
        require(shares != 0, CheddaPool_ZeroShares());
        _checkIsCollateralized(owner);
        _updatePoolState();
    }

    /// @notice Withdraws and burns a specified amount of shares.
    /// @dev If user has added this asset as collateral a collateral amount will be removed.
    /// if owner != msg.sender there must be an existing approval >= assetAmount
    /// @param shares The share amount to redeem.
    /// @param receiver The account to receive withdrawn assets
    /// @param owner The account to withdraw assets from.
    /// @return assetAmount The amount of assets repaid.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 assetAmount) {
        assetAmount = super.redeem(shares, receiver, owner);
        _checkIsCollateralized(owner);
        // zero_assets handled in ERC-4626
        _updatePoolState();
    }

    /// @notice Borrows asset from the pool.
    /// @dev The max amount a user can borrow must be less than the value of their collateral weighted
    /// against the loan to value ratio of that colalteral.
    /// Emits AssetBorrowed(account, amount, debt) event.
    /// @param amount The amount to borrow
    /// @return debtCreated The amount of debt token minted.
    function take(uint256 amount) external nonReentrant returns (uint256 debtCreated) {
        address account = msg.sender;
        _validateBorrow(account, amount);

        debtCreated = debtToken.createDebt(amount, account);
        _checkIsCollateralized(account);

        asset.safeTransfer(account, amount);
        _updatePoolState();

        emit AssetBorrowed(account, amount, debtCreated);
    }

    // repays a loan
    /// @notice Repays a part or all of a loan.
    /// @dev Emits AssetRepaid(account, amount, debtBurned).
    /// @param amount amount to repay. Must be > 0 and <= amount borrowed by sender
    /// @return debtBurned The amount of debt shares burned by this repayment.
    function putAmount(uint256 amount) external nonReentrant returns (uint256 debtBurned) {
        address account = msg.sender;
        if (amount == 0) {
            revert CheddaPool_ZeroAmount();
        }
        if (amount > assetsBorrowed(account)) {
            revert CheddaPool_Overpayment();
        }
        accrueInterest();
        asset.safeTransferFrom(account, address(this), amount);
        debtBurned = debtToken.repayAmount(amount, account);
        _updatePoolState();

        emit AssetRepaid(account, account, amount, debtBurned);
    }

    // repays a loan
    /// @notice Repays a part or all of a loan by specifying the amount of debt token to repay.
    /// @dev Emits AssetRepaid(account, amountRepaid, shares).
    /// @param shares The share of debt token to repay.
    /// @return amountRepaid the amount repaid.
    function putShares(uint256 shares) external nonReentrant returns (uint256 amountRepaid) {
        address account = msg.sender;
        accrueInterest();

        if (shares == 0) {
            revert CheddaPool_ZeroAmount();
        }
        if (shares > debtToken.accountShare(account)) {
            revert CheddaPool_Overpayment();
        }
        uint256 amountToTransfer = debtToken.convertToAssets(shares);
        asset.safeTransferFrom(account, address(this), amountToTransfer);
        amountRepaid = debtToken.repayShare(shares, account);
        _updatePoolState();

        emit AssetRepaid(account, account, amountRepaid, shares);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     Managing collateral logic
    ///////////////////////////////////////////////////////////////////////////

    function collateralize(bool useAsCollateral) external {
        _collateralize(useAsCollateral, msg.sender);

    }

    function _collateralize(bool useAsCollateral, address account) private {
        assetCollateralized[account] = useAsCollateral;

        emit CollaterallizeAsset(account, useAsCollateral);
    }

    /// @notice Add ERC-20 token collateral to pool.
    /// @dev Emits CollateralAdded(address token, address account, uint tokenType, uint amount).
    /// @param token The token to deposit as collateral.
    /// @param amount The amount of token to deposit.
    function addCollateral(
        address token,
        uint256 amount
    ) external nonReentrant {
        if (token == address(asset)) {
            revert CheddaPool_AssetMustBeSupplied();
        }
        _addCollateral(msg.sender, token, amount);
    }

    function _addCollateral(
        address account,
        address token,
        uint256 amount
    ) private {
        // check collateral is allowed
        if (!collateralAllowed[token]) {
            revert CheddaPool_CollateralNotAllowed(token);
        }

        // check amount
        if (amount == 0) {
            revert CheddaPool_ZeroAmount();
        }

        // account is always msg.sender
        ERC20(token).safeTransferFrom(account, address(this), amount);
        tokenCollateralDeposited[token] += amount;

        // add collateral to account
        if (_accountHasCollateral(account, token)) {
            accountCollateralDeposited[account][token].amount += amount;
        } else {
            CollateralDeposit memory deposit = CollateralDeposit({
                token: token,
                tokenType: TokenType.ERC20,
                amount: amount,
                tokenIds: new uint256[](0)
            });
            accountCollateralDeposited[account][token] = deposit;
        }

        emit CollateralAdded(token, account, TokenType.ERC20, amount);
    }

    /// @notice Removes ERC20 collateral from pool.
    /// @dev Emits CollateralRemoved(token, account, type, amount).
    /// @param token The collateral token to remove.
    /// @param amount The amount to remove.
    function removeCollateral(
        address token,
        uint256 amount
    ) external nonReentrant {
        if (token == address(asset)) {
            revert CheddaPool_AsssetMustBeWithdrawn();
        }
        _removeCollateral(msg.sender, token, amount);
        _checkIsCollateralized(msg.sender);
    }

    function _removeCollateral(
        address account,
        address token,
        uint256 amount
    ) private {
        if (amount == 0) {
            revert CheddaPool_ZeroAmount();
        }
        uint256 accountCollateral = accountCollateralAmount(account, token);
        if (amount > accountCollateral) {
            revert CheddaPool_InsufficientCollateral(
                account,
                token,
                amount,
                accountCollateral
            );
        }

        tokenCollateralDeposited[token] -= amount;

        if (accountCollateral == amount) {
            accountCollateralDeposited[account][token].token = address(0);
            accountCollateralDeposited[account][token].tokenType = TokenType.Invalid;
            accountCollateralDeposited[account][token].amount = 0;
            delete accountCollateralDeposited[account][token].tokenIds;
        } else {
            accountCollateralDeposited[account][token].amount -= amount;
        }

        ERC20(token).safeTransfer(account, amount);
        emit CollateralRemoved(token, account, TokenType.ERC20, amount);
    }

    /// Liquidations

    /// @notice Struct passed in to liquidation functions.
    /// @dev Contains parameters forliquidation.
    /// @param borrower The account being liquidated.
    /// @param receiver The receiver of seized collateral.
    /// @param collateral The collateral token to be received.
    /// @param repayAmount The amount of of loan asset to be repaid.
    struct LiquidateParams {
        address borrower;
        address receiver;
        address collateral;
        uint256 repayAmount;
    }

    /// @notice Allows an account to liquidate a borrower's position if their health factor falls below 1.0e18.
    /// @dev Throws the `CheddaPool_InvalidLiquidation` error if there is a mismatch in length of any of
    /// `borrowers`, `collateralTokens`, `repayAmounts`.
    /// Throws `CheddaPool_InvalidLiquidation` error if health of a borrower after liquidation is not
    /// greater than the health before liquidation.
    /// @param params Array of `LiquidateParams` objects specifying parameters for liquidations.
    /// @return collateralAmounts The amounts of collateral removed.
    function batchLiquidate(LiquidateParams[] calldata params) external nonReentrant() returns (uint256[] memory) {
        _updatePoolState();
        uint256 len = params.length;
        uint256[] memory collateralAmounts = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            collateralAmounts[i] = _liquidate(params[i]);
        }
        return collateralAmounts;
    }

    /// @dev Internal liquidate function. Liquidates a single position.
    /// @param params Array of `LiquidateParams` objects specifying parameters for liquidations.
    /// @return collateralRemoved The amount of collateral removed from borrower
    function _liquidate(
        LiquidateParams calldata params
    ) private returns (uint256) {
        uint256 initialHealth = accountHealth(params.borrower);
        if (initialHealth >= 1.0e18) {
            revert CheddaPool_AccountSolvent(params.borrower, initialHealth);
        }
        if (params.repayAmount == 0) {
            revert CheddaPool_ZeroAmount();
        }
        uint256 debtOwed = assetsBorrowed(params.borrower);
        if (params.repayAmount > debtOwed) {
            revert CheddaPool_Overpayment();
        }

        asset.safeTransferFrom(msg.sender, address(this), params.repayAmount);
        uint256 debtBurned = debtToken.repayAmount(params.repayAmount, params.borrower);

        (uint256 totalAmount, uint256 liquidatorAmount, uint256 reserveAmount) = _calculateLiquidationAmounts(params);

        if (params.collateral == address(asset)) {
            _liquidateAsset(params.borrower, totalAmount);
        } else {
            _liquidateCollateral(params.borrower, params.collateral, totalAmount);
        }

        ERC20(params.collateral).safeTransfer(params.receiver, liquidatorAmount);
        ERC20(params.collateral).safeTransfer(reserve, reserveAmount);

        emit AssetRepaid(params.borrower, params.receiver, params.repayAmount, debtBurned);
        emit PositionLiquidated(params.borrower, params.receiver, params.collateral, totalAmount);

        return totalAmount;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param params Array of `LiquidateParams` objects specifying parameters for liquidations.
    /// @return totalCollateralAmount The amount of collateral the liquidator received.
    function flashLiquidate(
        LiquidateParams memory params,
        address callback,
        bytes calldata data
    ) external nonReentrant() returns (uint256) {
        require(approvedCallbacks[callback], CheddaPool_CallbackNotApproved(callback));
        _updatePoolState();
        {
            uint256 health = accountHealth(params.borrower);
            if (health >= 1.0e18) {
                revert CheddaPool_AccountSolvent(params.borrower, health);
            }
        }
        if (params.repayAmount == 0) {
            revert CheddaPool_ZeroAmount();
        }
        if (params.repayAmount > assetsBorrowed(params.borrower)) {
            revert CheddaPool_Overpayment();
        }
        if (callback == address(0)) {
            revert CheddaPool_InvalidLiquidation();
        }

        // Extract collateral calculation to reduce stack
        (uint256 totalCollateralAmount, uint256 liquidatorAmount, uint256 reserveAmount) = _calculateLiquidationAmounts(params);

        uint256 debtBurned = debtToken.repayAmount(params.repayAmount, params.borrower);
        if (params.collateral == address(asset)) {
            _liquidateAsset(params.borrower, totalCollateralAmount);
        } else {
            _liquidateCollateral(params.borrower, params.collateral, totalCollateralAmount);
        }

        ERC20(params.collateral).safeTransfer(params.receiver, liquidatorAmount);
        ERC20(params.collateral).safeTransfer(reserve, reserveAmount);

        uint256 balanceBefore = asset.balanceOf(address(this));
        IFlashLiquidationCallback(callback).execute(data);

        uint256 balanceAfter = asset.balanceOf(address(this));
        require(balanceAfter >= balanceBefore + params.repayAmount,
            CheddaPool_InsufficientAssetBalance(balanceAfter, balanceBefore + params.repayAmount));

        emit AssetRepaid(params.borrower, params.receiver, params.repayAmount, debtBurned);
        emit PositionLiquidated(params.borrower, params.receiver, params.collateral, totalCollateralAmount);
        return totalCollateralAmount;
    }

    /// @dev calculate liquidation amount allocations
    function _calculateLiquidationAmounts(
        LiquidateParams memory params
    ) private view returns (uint256 totalAmount, uint256 liquidatorAmount, uint256 reserveAmount) {
        uint256 availableCollateral = accountCollateralAmount(params.borrower, params.collateral);
        uint256 baseAmount = calculateCollateralAmount(params.repayAmount, params.collateral, false);

        // Total collateral seized is baseAmount scaled by (1 + liqPenalty)
        totalAmount = ud(baseAmount)
            .mul(ud(1e18 + collateralParams[params.collateral].liqPenalty))
            .unwrap();

        // Liquidator amount is baseAmount plus bonus (baseAmount * liqBonus)
        liquidatorAmount = ud(baseAmount)
            .add(ud(baseAmount).mul(ud(collateralParams[params.collateral].liqBonus)))
            .unwrap();

        // Reserve amount is the difference
        reserveAmount = totalAmount - liquidatorAmount;

        // Ensure totalAmount doesn't exceed available collateral
        require(totalAmount <= availableCollateral, 
            CheddaPool_InsufficientCollateral(params.borrower, params.collateral, totalAmount, availableCollateral));

        // Sanity check for decimal correctness
        uint256 tokenDecimals = ERC20(params.collateral).decimals();
        require(totalAmount < 10**(tokenDecimals + 18), "Liquidation amount exceeds reasonable bounds");
    }

    function _liquidateAsset(
        address borrower,
        uint256 amount
    ) private {
        require(assetCollateralized[borrower], CheddaPool_InvalidLiquidation());
        uint256 availableBalance = assetBalance(borrower);
        if (amount > availableBalance) {
            revert CheddaPool_InsufficientCollateral(borrower, address(asset), amount, availableBalance);
        }

        uint256 shares = previewWithdraw(amount);
        if (convertToAssets(shares) < amount) {
            shares += 1; // Round up to ensure at least `amount` is removed
        }
        _burn(borrower, shares);
        supplied -= amount; // Sync with asset removal, like beforeWithdraw()

        // Optional: Emit event for transparency
        emit CollateralRemoved(address(asset), borrower, TokenType.ERC20, amount);
    }

    function _liquidateCollateral(
        address borrower,
        address token,
        uint256 amount
    ) private {
        uint256 accountCollateral = accountCollateralAmount(borrower, token);
        if (amount > accountCollateral) {
            revert CheddaPool_InsufficientCollateral(
                borrower,
                token,
                amount,
                accountCollateral
            );
        }

        tokenCollateralDeposited[token] -= amount;

        if (accountCollateral == amount) {
            accountCollateralDeposited[borrower][token].token = address(0);
            accountCollateralDeposited[borrower][token].tokenType = TokenType.Invalid;
            accountCollateralDeposited[borrower][token].amount = 0;
            delete accountCollateralDeposited[borrower][token].tokenIds;
        } else {
            accountCollateralDeposited[borrower][token].amount -= amount;
        }
        emit CollateralRemoved(token, borrower, TokenType.ERC20, amount);
    }

    /// View functions
    /// @notice Reads the price of an asset from the oracle
    /// @dev Explain to a developer any extra details
    /// @param asset The asset to return price for
    /// @param checkAge Check if the price has been updated recently. Revert if `checkAge` is true and price is stale.
    /// @return The price of the asset.
    function getPrice(address asset, bool checkAge) public view returns (uint256) {
        (int256 price, uint256 lastUpdated) = priceFeed.readPrice(asset);
        if (price < 0) {
            revert CheddaPool_BadPrice(asset, price.toUint256());
        }
        if (checkAge && block.timestamp - lastUpdated > stalePriceThreshold) {
            revert CheddaPool_StalePrice(asset, lastUpdated);
        }
        return price.toUint256();
    }

    /// @notice Returns the total value of an account including asset and collateral.
    /// @param account The account to get collateral value for.
    /// @param valueType Determines how the value is calculated. This is of enum `AccountValue`.
    /// @return accountValue The value of collateral deposited by account.
    function totalAccountCollateralValue(
        address account,
        AccountValue valueType
    ) public view returns (uint256 accountValue) {
        uint256 collateralValue;
        uint256 len = collateralTokenList.length;
        for (uint256 i = 0; i < len; i++) {
            address token = collateralTokenList[i];
            uint256 amount = accountCollateralAmount(account, token);
            if (amount != 0) {
                if (valueType == AccountValue.Loan) {
                    collateralValue = tokenLoanValue(token, amount);
                } else if (valueType == AccountValue.Liquidation) {
                    collateralValue = tokenLiquidationValue(token, amount);
                } else {
                    collateralValue = tokenMarketValue(token, amount);
                }
                if (collateralValue > 0) {
                    accountValue += collateralValue;
                }
            }
        }
    }

    /// @notice Returns the amount of a given token an account has deposited as collateral
    /// @param account The account to check collateral for
    /// @param collateral The collateral to check
    /// @return collateralAmount The amount of `collateral` token `account` has deposited.
    function accountCollateralAmount(
        address account,
        address collateral
    ) public view returns (uint256 collateralAmount) {
        if (collateral == address(asset)) {
            if (assetCollateralized[account]) collateralAmount = assetBalance(account);
            else collateralAmount = 0;
        } else {
            collateralAmount = accountCollateralDeposited[account][collateral].amount;
        }
    }

    /// @notice Returns the free collateral the account has for a given collateral token.
    /// @param account The account to check for.
    /// @param token The collateral.
    /// @return The free collateral amount.
    function freeAccountCollateralAmount(
        address account,
        address token
    ) external view returns (uint256) {
        uint256 debtValue = tokenMarketValue(
            address(asset),
            assetsBorrowed(account)
        );
        uint256 maxCollateralAmount = accountCollateralAmount(account, token);
        if (debtValue == 0) {
            return maxCollateralAmount;
        }
        uint256 collateralValue = totalAccountCollateralValue(account, AccountValue.Loan);
        if (collateralValue == 0 || debtValue >= collateralValue) {
            return 0;
        }
        uint256 freeCollateralValue = collateralValue - debtValue;
        uint256 collateralUnitValue = getPrice(token, false);
        uint256 freeCollateralAmountE18 = ud(freeCollateralValue)
            .div(ud(collateralUnitValue.normalized(priceFeed.decimals(), 18))).unwrap();
        uint256 collateralAmount = freeCollateralAmountE18.normalized(18, ERC20(token).decimals());
        return maxCollateralAmount > collateralAmount ? collateralAmount : maxCollateralAmount;
    }

    /// @notice Returns the amount of asset an account has borrowed, including any accrued interest.
    /// @param account The account to check for.
    /// @return amount The amount of account borrowed by `account`.
    function assetsBorrowed(
        address account
    ) public view returns (uint256) {
        uint256 shares = debtToken.accountShare(account);
        if (shares == 0) return 0;
        return debtToken.convertToAssets(shares) + 1; // convertToAssets rounds down. Round up to account for this.
    }

    /// @notice Returns the health ratio of the account
    /// health > 1.0 means the account is solvent.
    /// health <1.0 but != 0 means account is insolvent
    /// health == 0 means account has no debt and is also solvent.
    /// @param account The account to check.
    /// @return health The health ration of the account, to 1e18. i.e 1e18 = 1.0 health.
    function accountHealth(address account) public view returns (uint256 health) {
        // TODO: add test for max account health
        uint256 debtValue = tokenMarketValue(
            address(asset),
            assetsBorrowed(account)
        );
        if (debtValue == 0) {
            health = maxAccountHealth;
        } else {
            health = ud(totalAccountCollateralValue(account, AccountValue.Liquidation))
                .div(ud(debtValue))
                .unwrap();
            health = health > maxAccountHealth ? maxAccountHealth : health;
        }
    }

    /// @dev returns true if account has deposited a given token as collateral
    function _accountHasCollateral(
        address account,
        address collateral
    ) private view returns (bool hasCollateral) {
        hasCollateral = accountCollateralDeposited[account][collateral].amount != 0;
    }

    function collaterals() external view returns (address[] memory) {
        return collateralTokenList;
    }

    function calculateCollateralAmount(
        uint256 assetAmount,
        address collateralToken,
        bool useLTV
    ) public view returns (uint256 collateralAmount) {
        uint256 assetPrice = getPrice(address(asset), true); // Price of asset token
        uint256 collateralPrice = getPrice(collateralToken, true); // Price of collateral token
        uint256 ltvCoeff = useLTV ? collateralParams[collateralToken].ltv : 1e18;
        require(ltvCoeff > 0, CheddaPool_UnsupportedCollateral(collateralToken));
        require(collateralPrice != 0, CheddaPool_BadPrice(collateralToken, collateralPrice));

        // Calculate: (assetAmount * assetPrice) / (collateralPrice * ltvCoeff)
        // Adjust for decimals: prices are in priceFeed.decimals(), amounts in token decimals
        uint8 assetDecimals = ERC20(address(asset)).decimals();
        uint8 collateralDecimals = ERC20(collateralToken).decimals();
        uint8 priceDecimals = priceFeed.decimals();

        // Normalize to 18 decimals for intermediate calculations
        UD60x18 value = ud(assetAmount.normalized(assetDecimals, 18))
            .mul(ud(assetPrice.normalized(priceDecimals, 18)));
        UD60x18 denominator = ud(collateralPrice.normalized(priceDecimals, 18))
            .mul(ud(ltvCoeff));
        collateralAmount = value.div(denominator).unwrap();
        
        // Convert result back to collateral token's native decimals
        collateralAmount = collateralAmount.normalized(18, collateralDecimals);

        require(collateralAmount != 0, CheddaPool_ZeroAmount());
    }

    /// @notice Returns the market value of a given number of token.
    /// @param token The token to return value for.
    /// @param amount The amount of token to calculate the value of.
    /// @return value The market value of `amount` of `token`.
    function tokenMarketValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getPrice(token, false);
        return
            ud(price.normalized(priceFeed.decimals(), 18))
                .mul(ud(amount.normalized(ERC20(token).decimals(), 18)))
                .unwrap();
    }

    /// @notice Returns the value as collateral for a given amount of token
    /// @dev This takes into account the loan to value (LTV) ratio.
    /// @param token The token to return value for.
    /// @param amount The amount of token to calculate the value of.
    /// @return value The collateral value of `amount` of `token`.
    function tokenLoanValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getPrice(token, false);
        return
            (
                ud(price.normalized(priceFeed.decimals(), 18)).mul(
                    ud(amount.normalized(ERC20(token).decimals(), 18))
                )
            ).mul(ud(collateralParams[token].ltv)).unwrap();

    }

    /// @notice Returns the value as collateral for a given amount of token
    /// @dev This takes into account the lltv.
    /// @param token The token to return value for.
    /// @param amount The amount of token to calculate the value of.
    /// @return value The collateral value of `amount` of `token`.
    function tokenLiquidationValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getPrice(token, false);
        return
            (
                ud(price.normalized(priceFeed.decimals(), 18)).mul(
                    ud(amount.normalized(ERC20(token).decimals(), 18))
                )
            ).mul(ud(collateralParams[token].lltv)).unwrap();
    }

    /// @notice Returns the collateral configuration for a given token;
    /// @param token The token to return collateral info for.
    /// @return The `CollateralParams` for requested token.
    function collateralInfo(address token) external view returns (CollateralParams memory) {
        return collateralParams[token];
    }

    /// @dev take a snapshot of the current pool state.
    function updatePoolState() external {
        _updatePoolState();
    }

    /// @notice Checks if account is solvent.
    /// In simple terms, an account is solvent if collateralMarketValue * liquidation threshold > debt.
    /// @param account account to check for.
    /// @return If the account is solvent.
    function isSolvent(address account) external view returns (bool) {
        uint256 accountBorrowed = assetsBorrowed(account);
        if (accountBorrowed == 0) return true;

        uint256 debtValue = tokenMarketValue(
            address(asset),
            accountBorrowed
        );
        return totalAccountCollateralValue(account, AccountValue.Liquidation) >= debtValue;
    }

    /// @notice Checks if account has enough collateral after currnet operation completes.
    /// @dev In simple terms, an account is collateralized if collateralMarketValue * ltv > debt.
    /// @param account account to check for.
    /// @return If the account is collateralized.
    function isCollateralized(address account) public view returns (bool) {
        uint256 debtValue = tokenMarketValue(
            address(asset),
            assetsBorrowed(account)
        );
        return totalAccountCollateralValue(account, AccountValue.Loan) >= debtValue;
    }

    function _checkIsCollateralized(address account) private view {
        require (isCollateralized(account), CheddaPool_AccountNotCollateralized(account));
    }

    //// @notice Checks that the amount being borrowed is less than the borrow cap.
    //// @dev reverts if amount > borrowCap
    //// @param account The account to check for.
    //// @param amount The amount being borrowed by this user.
    // function _checkBorrowCaps(address account, uint256 amount) private view {
    //     if (icm) {
            
    //     } else {

    //     }
    // }

    function _checkSupplyCap() private view {
        if (supplied > supplyCap) {
            revert CheddaPool_SupplyCapExceeded(supplyCap, supplied);
        }
    }

    /// To validate borrow
    /// 1. Check that funds are available.
    function _validateBorrow(address, uint256 amount) private view {
        uint256 amountAvailable = available();
        require(amountAvailable >= amount,
            CheddaPool_InsufficientAssetBalance(amountAvailable, amount));
    }

    function accrueInterest() public {
        _accrue();
    }

    function _accrue() private {
        uint256 timestamp =  block.timestamp;
        uint256 totalDebt = debtToken.totalDebt();
        // no accrual if no debt exists
        if (totalDebt == 0) {
            return;
        }

        // initialize `_lastAccrual` if not yet initialized
        if (_lastAccrual == 0) {
            _lastAccrual = timestamp;
        }
        uint256 elapsedTime = timestamp - _lastAccrual;
        if (elapsedTime == 0) {
            return;
        }
        // interestRates already updated
        uint256 borrowRatePerSecond = interestRates.borrowRate / SECONDS_PER_YEAR;
        uint256 interest = ud(totalDebt).mul(ud(borrowRatePerSecond * elapsedTime)).unwrap();

        debtToken.addInterest(interest);
        _addSupplyInterest(interest);
        _mintToReserve(ud(interest).mul(ud(reserveFactor)).unwrap());

        _lastAccrual = timestamp;
        emit InterestAccrued(
            msg.sender, 
            interest, 
            debtToken.totalDebt(), 
            totalAssets()
        );
    }

    /// @dev accrues supply interest
    function _addSupplyInterest(uint256 interestAmount) private {
        supplied += interestAmount;
    }

    function _mintToReserve(uint256 reserveAmount) private {
        uint256 shares = convertToShares(reserveAmount);
        totalReserveShares += shares;
        _mint(reserve, shares);

        emit MintToReserve(msg.sender, shares, reserveAmount);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     ERC4626 overrides
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns the asset that can be borrowed from this pool
    /// @return asset The pool asset
    function poolAsset() external view returns (ERC20) {
        return asset;
    }

    /// @notice The amount of asset an account can access.
    /// @dev This is based on the number of pool shares an account holds.
    /// @param account The account to check the balance of.
    /// @return amount The amount of asset an account holds in the pool.
    function assetBalance(address account) public view returns (uint256) {
        return convertToAssets(balanceOf[account]);
    }

    /// @notice The total amount of asset deposited into the pool.
    /// @dev This includes assets that have been borrowed.
    /// @return amount The total assets supplied to pool.
    function totalAssets() public view override returns (uint256) {
        return supplied; // TODO: add accrued interest
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     ERC20 overrides
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Transfer tokens from caller to another address.
    /// @dev Overrides ERC-20 transfer to add health checks after transfers
    /// @param to address to send to
    /// @param amount amount to send
    /// @return success True if transfer is successful, false otherwise.
    function transfer(address to, uint256 amount) public override returns (bool success) {
        success = super.transfer(to, amount);
        _checkIsCollateralized(msg.sender);
        _checkIsCollateralized(to);
    }

    /// @notice Transfer tokens from a given address to another.
    /// @dev Overrides ERC-20 transferFrom to add health checks after transfers. 
    /// Caller must have an allowance to transfer from `from` address.
    /// @param from address to send from
    /// @param to address to send to
    /// @param amount amount to send
    /// @return success True if transfer is successful, false otherwise.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool success) {
        success = super.transferFrom(from, to, amount);
        _checkIsCollateralized(from);
        _checkIsCollateralized(to);
    }
    
    /// @notice The assets available to be borrowed from pool.
    /// @return assetAmount The amount of asset available in pool.
    function available() public view returns (uint256 assetAmount) {
        assetAmount = asset.balanceOf(address(this));
    }

    /// @notice The assets borrowed from pool.
    /// @return assetAmount The amount of asset borrowed from pool, including accrued interest.
    function borrowed() public view returns (uint256 assetAmount) {
        assetAmount = debtToken.totalDebt();
    }

    /// @notice The total value locked in this pool.
    /// @dev TVL is calculated as assets supplied + collateral deposited.
    /// @param countBorrows Flag indicating if the borrows should be included in TVL calculation.
    /// @return totalValue The total value locked in pool.
    function tvl(bool countBorrows) external view returns (uint256 totalValue) {
        address collateral;
        uint256 len = collateralTokenList.length;
        for (uint256 i = 0; i < len; i++) {
            collateral = collateralTokenList[i];
            uint256 amount = ERC20(collateral).balanceOf(address(this));
            totalValue += tokenMarketValue(collateral, amount);
        }
        if (countBorrows) {
            uint256 borrows = debtToken.totalDebt();
            totalValue += tokenMarketValue(address(asset), borrows);
        }
    }

    //////////////////////////////////////////////////////////////////////////
    ///                         Interest rates
    //////////////////////////////////////////////////////////////////////////

    /// @notice Returns the base supply APY.
    /// @dev This is the interest earned on supplied assets.
    /// @return apy The interest earned on supplied assets.
    function baseSupplyAPY() external view returns (uint256 apy) {
        apy = interestRates.supplyRate;
    }

    /// @notice Returns the base borrow APY.
    /// @dev This is the interest paid on borrowed assets.
    /// @return apy The interest paid on borrowed assets.
    function baseBorrowAPY() external view returns (uint256 apy) {
        apy = interestRates.borrowRate;
    }

    /// @notice The pool asset utilization
    /// @dev This is the amount of asset borrowed divided by assets supplied.
    /// @return u The pool asset utilization.
    function utilization() public view returns (uint256 u) {
        u = _simpleUtilization();
    }

    /// @dev placeholder function for utilization
    function _simpleUtilization() private view returns (uint256) {
        if (supplied == 0) {
            return 0;
        }
        return
            ud(borrowed())
                .div(ud(supplied))
                .unwrap();
    }

    /// @dev recapitalizes the pool
    function recapitalize() external pure returns (uint256) {
        return 0;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                        deposit/withdraw hooks
    ///////////////////////////////////////////////////////////////////////////
    // solhint-disable-next-line private-vars-leading-underscore
    function beforeWithdraw(uint256 assets, uint256) internal override {
        supplied -= assets;
    }

    // solhint-disable-next-line private-vars-leading-underscore
    function afterDeposit(uint256 assets, uint256) internal override {
        supplied += assets;
        _checkSupplyCap();
    }

    /// Interest rates
    function updateInterestRates() private {
        interestRates = interestRatesModel.calculateInterestRates(
            utilization()
        );
    }

    function _updatePoolState() private {
        updateInterestRates();
        accrueInterest();
        _emitPoolState();
    }

    function _emitPoolState() private {
        emit PoolState(
            address(this),
            msg.sender,
            block.timestamp,
            supplied,
            borrowed(),
            interestRates.supplyRate,
            interestRates.borrowRate
        );
    }

    /// @notice Returns the version of the pool
    /// @return The version
    function version() external pure returns (uint16) {
        return 1;
    }
}

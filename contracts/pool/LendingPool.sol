// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { DebtToken } from "../tokens/DebtToken.sol";
import { IInterestRateModel, InterestRates } from "./IInterestRateModel.sol";
import { SimpleInterestRateModel } from "./SimpleInterestRateModel.sol";
import { LinearInterestRateModel } from "./LinearInterestRateModel.sol";
import { IPriceFeed } from "../oracle/IPriceFeed.sol";
import { ILendingPool } from "./ILendingPool.sol";
import { ILiquidityGauge } from "../gauge/ILiquidityGauge.sol";
import { console2 } from "forge-std/console2.sol";

/// @title LendingPool
/// @notice Implements supply and borrow functionality.
/// @dev Implements ERC4626 interface.

/// TODO: check prices are positive and no overflow/underflow when using prices
contract LendingPool is ERC4626, Ownable, ReentrancyGuard, ILendingPool {

    /// TODO: 
    /// 1. collateralize while supplying.
    /// 2. collateralize/uncollateralize after supply

    /// @dev The type of the collateral.
    /// Options are ERC20, ERC721 and ERC1155.
    enum TokenType {
      ERC20,
      ERC721,
      ERC155
    }

    /// @notice Holds information about the type of collateral held in vault.
    /// @param token The address of the token
    /// @param collateralFactor The collateral factor.
    /// @param tokenType The type of token (ERC20, ERC721, ERC1155)
    struct CollateralInfo {
        address token;
        uint256 collateralFactor;
        TokenType tokenType;
    }

    /// Custom errors
    /// @notice This is the current state of vault key stats, returned as a view.
    /// Some fields are computed.
    /// @dev move to LendingPoolView?
    struct VaultStateView {
        uint256 supplied;
        uint256 borrowed; // this is debt including interest
        uint256 available;
        uint256 utilization;
        uint256 baseSupplyApr;
        uint256 baseBorrowApr;
        uint256 maxSupplyRewardsApr;
        uint256 maxBorrowRewardsApr;
        uint256 max;
    }

    /// @dev Information about collateral deposited to the pool.
    struct CollateralDeposited {
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

    /// Events

    /// @notice Emitted when collateral is added
    /// @param token The token added
    /// @param account The account that added the collateral.
    /// @param ofType The type of collateral
    /// @param amount The amount of token added as collateral
    event CollateralAdded(address indexed token, address indexed account, TokenType ofType, uint256 amount);

    /// @notice Emitted when collateral is removed
    /// @param token The token removed.
    /// @param account The account that removed the collateral.
    /// @param ofType The type of collateral
    /// @param amount The amount of token removed as collateral
    event CollateralRemoved(address indexed token, address indexed account, TokenType ofType, uint256 amount);

    /// @notice Emitted when assets are borrowed.
    /// @param account The account that borrowed assets.
    /// @param amount The amount of assets borrowed.
    /// @param debtMinted The amount of debt token created.
    event AssetBorrowed(address indexed account, uint256 amount, uint256 debtMinted);
    
    /// @notice Emitted when borrowed assets are repaid.
    /// @param account The account that repaid assets.
    /// @param amount The amount of assets repaid.
    /// @param debtBurned The amount of debt token burned.
    event AssetRepaid(address indexed account, uint256 amount, uint256 debtBurned);

    /// @notice Emitted when the rewards gauge is set
    /// @param gauge The gauge address.
    /// @param caller The account that set the gauge.
    event GaugeSet(address indexed gauge, address indexed caller);

    /// Custom errors
    error CheddaPool_InvalidPrice(int256 price, address token);
    error CheddaPool_CollateralNotAllowed(address token);
    error CheddaPool_WrongCollateralType(address token);
    error CheddaPool_ZeroAmount();
    error CheddaPool_InsufficientCollateral(address account, address token, uint256 amountRequested, uint256 amountDeposited);
    error CheddaPool_AccountInsolvent(address account, uint256 health);
    error CheddaPool_InsufficientAssetBalance(uint256 available,uint256 requested);
    error CheddaPool_Overpayment();

    using SafeCast for int256;
    using SafeTransferLib for ERC20;

    /// state vars
    uint256 public supplied;
    uint256 public feesPaid;

    string public characterization;

    /// Debt and interest
    DebtToken public immutable debtToken;
    IPriceFeed public immutable priceFeed;
    InterestRates public interestRates;
    IInterestRateModel public interestRateModel;
    ILiquidityGauge public gauge;

    /// Collateral

    // list of tokens that can be used as collateral
    address[] public collateralTokenList;

    // token address => is allowed
    mapping(address => bool) public collateralAllowed;

    // token address => TokenType
    mapping(address => TokenType) public collateralTokenTypes;

    // Determines Loan to Value ratio for token
    mapping(address => uint256) public collateralFactor;
    
    // account => token => amount
    mapping(address => mapping(address => CollateralDeposited)) public accountCollateralDeposited;
    
    // token address => Collateral amount
    // use to be tokenCollateral
    mapping(address => uint256) public tokenCollateralDeposited;

    uint256 private _assetCollateralDeposited;

    ///////////////////////////////////////////////////////////////////////////
    ///                         initialization
    ///////////////////////////////////////////////////////////////////////////

    constructor(string memory _name, ERC20 _asset, address _priceFeed, CollateralInfo[] memory _collateralTokens) 
    Ownable(msg.sender) // TODO: pass owner as admin
    ERC4626(
        _asset,
        string(abi.encodePacked("CHEDDA Token ", _asset.name())), 
        string(abi.encodePacked("ch", _asset.symbol()))) {
        // TODO: set interest rates strategy externally
        interestRateModel = new LinearInterestRateModel(
            0.05e18,
            0.1e18,
            0.9e18
        );
        interestRateModel = new SimpleInterestRateModel(
            0.05e18, // linear rate
            2.0e18, // exponential rate
            0.94e18 // target utilization
        );
        characterization = _name;
        priceFeed = IPriceFeed(_priceFeed);
        debtToken = new DebtToken(_asset, address(this));
        _initialize(_collateralTokens);
    }

    function _initialize(CollateralInfo[] memory _collateralTokens) private {
        _setCollateralTokenList(_collateralTokens);
    }

    /// @notice Sets the list of tokens that can be used as collateral in this pool.
    function _setCollateralTokenList(CollateralInfo[] memory list) private {
        for (uint256 i = 0; i < list.length; i++) {
            address collateral = list[i].token;
            collateralTokenList.push(collateral);
            collateralAllowed[collateral] = true;
            collateralTokenTypes[collateral] = list[i].tokenType;
            collateralFactor[collateral] = list[i].collateralFactor;
        }
    }

    /*///////////////////////////////////////////////////////////////
                        borrow/repay logic
    //////////////////////////////////////////////////////////////*/

    /// TODO: Manage collateral with supply, withdraw, redeem

    /// @notice Supplies assets to pool
    /// @param amount The amount to supply
    /// @param receiver The account to mint share tokens to
    /// @param useAsCollateral Whethe this deposit should be marked as collateral
    /// @return shares The amount of shares minted.
    function supply(uint256 amount, address receiver, bool useAsCollateral) external nonReentrant() returns (uint256) {
        uint256 shares = deposit(amount, receiver);
        if (useAsCollateral) {
            _addCollateral(address(asset), amount, false);
            _assetCollateralDeposited += amount;
        }
        return shares;
    }

    /// @notice Withdraws a specified amount of assets from pool
    /// @dev If user has added this asset as collateral a collateral amount will be removed.
    /// if owner != msg.sender there must be an existing approval >= assetAmount
    /// @param assetAmount The amount to withdraw
    /// @param receiver The account to receive withdrawn assets
    /// @param owner The account to withdraw assets from.
    /// @return shares The amount of shares burned by withdrawal.
    function withdraw(uint256 assetAmount, address receiver, address owner) public override nonReentrant() returns (uint256) {
        uint256 shares = super.withdraw(assetAmount, receiver, owner);
        if (_accountHasCollateral(msg.sender, address(asset))) {
            // TODO: Handle case where collateral < assetAmount
            _removeCollateral(address(asset), assetAmount);
            _assetCollateralDeposited -= assetAmount;
        }
        return shares;
    }

    /// @notice Withdraws and burns a specified amount of shares.
    /// @dev If user has added this asset as collateral a collateral amount will be removed.
    /// if owner != msg.sender there must be an existing approval >= assetAmount
    /// @param shares The share amount to redeem.
    /// @param receiver The account to receive withdrawn assets
    /// @param owner The account to withdraw assets from.
    /// @return assetAmount The amount of assets repaid.
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant() returns (uint256) {
        uint256 assetAmount = super.redeem(shares, receiver, owner);
        if (_accountHasCollateral(msg.sender, address(asset))) {
            _removeCollateral(address(asset), assetAmount);
        }
        return assetAmount;
    }

    /// @notice Borrows asset from the pool.
    /// @dev The max amount a user can borrow must be less than the value of their collateral weighted
    /// against the loan to value ratio of that colalteral.
    /// Emits AssetBorrowed(account, amount, debt) event.
    /// @param amount The amount to borrow
    /// @return debt The amount of debt token minted.
    function take(uint256 amount) external returns (uint256) {
        address account = msg.sender;
        _validateBorrow(account, amount);
    
        uint256 debt = debtToken.createDebt(amount, account);
        _calculateIntrestRates(0, amount);
        _checkAccountHealth(account);

        asset.safeTransfer(account, amount);
        emit AssetBorrowed(account, amount, debt);

        return debt;
    }

     // repays a loan
    /// @notice Repays a part or all of a loan.
    /// @dev Emits AssetRepaid(account, amount, debtBurned).
    /// @param amount amount to repay. Must be > 0 and <= amount borrowed by sender
    /// @return The amount of debt shares burned by this repayment.
    function putAmount(uint256 amount) external returns (uint256) {
        address account = msg.sender;
        if (amount == 0) {
            revert CheddaPool_ZeroAmount();
        }
        if (amount > accountAssetsBorrowed(account)) {
            revert CheddaPool_Overpayment();
        }
        _calculateIntrestRates(amount, 0);
        asset.safeTransferFrom(account, address(this), amount);
        uint256 debtBurned = debtToken.repayAmount(amount, account);

        emit AssetRepaid(account, amount, debtBurned);

        return debtBurned;
    }

    // repays a loan
    /// @notice Repays a part or all of a loan by specifying the amount of debt token to repay.
    /// @dev Emits AssetRepaid(account, amountRepaid, shares).
    /// @param shares The share of debt token to repay.
    /// @return amountRepaid the amount repaid.
    function putShares(uint256 shares) external returns (uint256) {
        address account = msg.sender;
        
        if (shares == 0) {
            revert CheddaPool_ZeroAmount();
        }
       if (shares > debtToken.accountShare(account)) {
            revert CheddaPool_Overpayment();
        } 
        uint256 amountToTransfer = debtToken.convertToAssets(shares);
        asset.safeTransferFrom(msg.sender, address(this), amountToTransfer);
        uint256 amountRepaid = debtToken.repayShare(shares, account);

        emit AssetRepaid(account, amountRepaid, shares);

        return amountRepaid;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     Managing collateral logic
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Add ERC-20 token collateral to pool.
    /// @dev Emits CollateralAdded(address token, address account, uint tokenType, uint amount).
    /// @param token The token to deposit as collateral.
    /// @param amount The amount of token to deposit.
    function addCollateral(address token, uint256 amount) external nonReentrant() {
        _addCollateral(token, amount, true);
    }

    function _addCollateral(address token, uint256 amount, bool doTransfer) private {
        // check collateral is allowed
        if (!collateralAllowed[token]) {
            revert CheddaPool_CollateralNotAllowed(token);
        }

        // check the collateral is ERC20
        if (collateralTokenTypes[token] != TokenType.ERC20) {
            revert CheddaPool_WrongCollateralType(token);
        }
        // check amount
        if (amount <= 0) {
            revert CheddaPool_ZeroAmount();
        }

        address account = msg.sender;
        
        if (doTransfer) {
            ERC20(token).safeTransferFrom(account, address(this), amount);
        }
        tokenCollateralDeposited[token] += amount;

        // add collateral to account
        if (_accountHasCollateral(account, token)) {
            accountCollateralDeposited[account][token].amount += amount;
        } else {
            CollateralDeposited memory deposit = CollateralDeposited({
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
    function removeCollateral(address token, uint256 amount) external nonReentrant() {
        _removeCollateral(token, amount);
    }

    function _removeCollateral(address token, uint256 amount) private {
        address account = msg.sender;
        if (amount <= 0) {
            revert CheddaPool_ZeroAmount();
        }
        uint256 accountCollateral = accountCollateralAmount(account, token);
        if (amount > accountCollateral){
            revert CheddaPool_InsufficientCollateral(account, token, amount, accountCollateral);
        }

        tokenCollateralDeposited[token] -= amount;

        if (accountCollateral == amount) {
            delete accountCollateralDeposited[account][token];
        } else {
            accountCollateralDeposited[account][token].amount -= amount;
        }

        _checkAccountHealth(account);

        ERC20(token).safeTransfer(msg.sender, amount);

        emit CollateralRemoved(token, account, TokenType.ERC20, amount);
    }

    /// @notice Get the token IDs deposited by this account
    /// @dev `collateral` parameter should be an ERC-721 token.
    /// @param account The account to check for
    /// @param collateral The collateral to check for
    /// @return tokenIds the token ids from the `collateral` NFT deposited by `account`.
    function accountCollateralTokenIds(address account, address collateral) external view returns (uint256[] memory) {
        CollateralDeposited memory c = accountCollateralDeposited[account][collateral];
        return c.tokenIds;
    }

    /// @notice Returns the total value of collateral deposited by an account.
    /// @param account The account to get collateral value for.
    /// @return totalValue The value of collateral deposited by account.
    function totalAccountCollateralValue(address account)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            address token = collateralTokenList[i];
            CollateralDeposited memory collateral = accountCollateralDeposited[account][token];
            if (_accountHasCollateral(account, token)) {
                uint256 amount = collateral.amount;
                uint256 collateralValue = getTokenCollateralValue(token, amount);
                if (collateralValue > 0) {
                    totalValue += collateralValue;
                }
            }
        }

        return totalValue;
    }

    /// TODO: remove. Renamed from `accountCollateralCount`.
    /// @notice Returns the amount of a given token an account has deposited as collateral
    /// @param account The account to check collateral for
    /// @param collateral The collateral to check 
    /// @return amount The amount of `collateral` token `account` has deposited.
    function accountCollateralAmount(address account, address collateral) public view returns (uint256) {
        return accountCollateralDeposited[account][collateral].amount;
    }

    /// TODO: remove. Renamed from `accountPendingAmount`
    /// @notice Returns the amount of asset an account has borrowed, including any accrued interest.
    /// @param account The account to check for.
    /// @return amount The amount of account borrowed by `account`.
    function accountAssetsBorrowed(address account) public view returns (uint256) {
        uint256 shares = debtToken.accountShare(account);
        return debtToken.convertToAssets(shares);
    }

    function debtValue(uint256 assetAmount) public view returns (uint256) {
        int256 assetPrice = priceFeed.readPrice(address(asset), 0);
        if (assetPrice < 0) {
            revert CheddaPool_InvalidPrice(assetPrice, address(asset));
        }
        return assetAmount * assetPrice.toUint256();
    }

    /// @notice Returns the health ratio of the account
    /// health > 1.0 means the account is solvent.
    /// health <1.0 but != 0 means account is insolvent
    /// health == 0 means account has no debt and is also solvent.
    /// @param account The account to check.
    /// @return health The health ration of the account, to 1e18. i.e 1e18 = 1.0 health.
    function accountHealth(address account) public view returns (uint256) {
        uint256 debt = accountAssetsBorrowed(account);
        if (debt == 0) {
            return type(uint256).max;
        }
        uint256 collateral = totalAccountCollateralValue(account); 
        return ud(collateral).div(ud(debt)).unwrap();
    }

    /// @dev returns true if account has deposited a given token as collateral
    function _accountHasCollateral(address account, address collateral) private view returns (bool) {
        return accountCollateralDeposited[account][collateral].token != address(0);
    }

    function collaterals() external view returns (address [] memory) {
        return collateralTokenList;
    }

    /// @notice Returns the market value of a given number of token.
    /// @param token The token to return value for.
    /// @param amount The amount of token to calculate the value of.
    /// @return value The market value of `amount` of `token`.
    function getTokenMarketValue(address token, uint256 amount) public view returns (uint256) {
        int256 price = priceFeed.readPrice(token, 0);
        // if (price < 0) {
        //     revert CheddaPool_InvalidPrice(price, token);
        // }
        return price.toUint256() * amount;
    }

    /// @notice Returns the value as collateral for a given amount of token
    /// @dev This takes into account the collateral factor of the token.
    /// @param token The token to return value for.
    /// @param amount The amount of token to calculate the value of.
    /// @return value The collateral value of `amount` of `token`.
    function getTokenCollateralValue(address token, uint256 amount) public view returns (uint256) {
        int256 price = priceFeed.readPrice(token, 0);
        // if (price < 0) {
        //     revert CheddaPool_InvalidPrice(price, token);
        // }
        console2.log("calculating value %d * %d / %d", price.toUint256(), amount, collateralFactor[token]);
        return (ud(price.toUint256()).mul(ud(amount))).mul(ud(collateralFactor[token])).unwrap();
    }

    function _checkAccountHealth(address account) private view {
        uint256 health = accountHealth(account);
        if (health < 1.0e18) { // 0 health means no debt
            revert CheddaPool_AccountInsolvent(account, health);
        }
    }

    /// To validate borrow
    /// 1. Check that funds are available.
    function _validateBorrow(address, uint256 amount) private view {
        uint256 amountAvailable = available();
        if (amountAvailable <= amount) {
            revert CheddaPool_InsufficientAssetBalance(amountAvailable, amount);
        }
    }

    /// ERC4626 overrides

    /// @notice Returns the asset that can be borrowed from this pool
    /// @return asset The pool asset
    function poolAsset() public view returns (ERC20) {
        return asset;
    }

    /// @notice The amount of asset an account can access.
    /// @dev This is based on the number of pool shares an account holds.
    /// @param account The account to check the balance of.
    /// @return amount The amount of asset an account holds in the pool.
    function assetBalance(address account) external view returns (uint256) {
        return convertToAssets(balanceOf[account]);
    }

    /// @notice The total amount of asset deposited into the pool.
    /// @dev This includes assets that have been borrowed.
    /// @return amount The total assets supplied to pool.
    function totalAssets() public override view returns (uint256) {
        return supplied;
    }

    /// @notice The assets available to be borrowed from pool.
    /// @return assetAmount The amount of asset available in pool.
    function available() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// @notice The assets borrowed from pool.
    /// @return assetAmount The amount of asset borrowed from pool.
    function borrowed() public view returns (uint256) {
        return supplied - available();
    }

    /// @notice The total value locked in this pool.
    /// @dev TVL is calculated as assets supplied + collateral deposited.
    /// @return tvl The total value locked in pool.
    function tvl() external view returns (uint256) {
        UD60x18 assetValue = ud(totalAssets()).mul(ud(priceFeed.readPrice(address(asset), 0).toUint256()));
        UD60x18 totalCollateralValue = ud(0);
        address collateral;
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            collateral = collateralTokenList[i];
            uint256 collateralAmount = tokenCollateralDeposited[collateral];
            //  if (collateral == address(asset)) {
            //     console2.log("*** assetValue = %d, marketValue = %d, assetCollateralDeposited = %d", assetValue.unwrap(), totalCollateralValue.unwrap(), _assetCollateralDeposited);
            //     collateralAmount -= _assetCollateralDeposited;
            // }
            uint256 marketValue = getTokenMarketValue(collateral, collateralAmount);
            console2.log("*** collateramAmount[%s] = %d, value = %d", collateral, collateralAmount, marketValue);
            totalCollateralValue.add(ud(marketValue));
           
        }
        return assetValue.add(totalCollateralValue).unwrap();
    }

    //////////////////////////////////////////////////////////////////////////
    ///                         Interest rates
    //////////////////////////////////////////////////////////////////////////

    /// @notice Returns the base supply APY.
    /// @dev This is the interest earned on supplied assets.
    /// @return apy The interest earned on supplied assets.
    function baseSupplyAPY() external view returns (uint256) {
        return interestRateModel.calculateInterestRate(utilization());
    }

    /// @notice Returns the base borrow APY.
    /// @dev This is the interest paid on borrowed assets.
    /// @return apy The interest paid on borrowed assets.
    function baseBorrowAPY() external view returns (uint256) {
        return interestRateModel.calculateInterestRate(utilization());
    }

    /// @notice The pool asset utilization
    /// @dev This is the amount of asset borrowed divided by assets supplied.
    /// @return utilization The pool asset utilization.
    function utilization() public view returns (uint256) {
        // totalDeposits - assetBalance / totalDeposits
        // also account for repayments
        return _simpleUtilization();
    }

    /// @notice Set the rewards gauge for this pool.
    /// @dev Can only be called by contract owner
    /// Emits GaugeSet(gauge, caller).
    function setGauge(address _gauge) external onlyOwner() {
        gauge = ILiquidityGauge(_gauge);
        emit GaugeSet(_gauge, msg.sender);
    }

    /// @dev placeholder function for utilization
    function _simpleUtilization() private view returns (uint256) {
        if (supplied == 0) {
            return 0;
        }
        return ud(supplied - asset.balanceOf(address(this))).div(ud(supplied)).unwrap();
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                        deposit/withdraw hooks
    ///////////////////////////////////////////////////////////////////////////
    // solhint-disable-next-line private-vars-leading-underscore
    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        shares;
        supplied -= assets;
        _calculateIntrestRates(0, assets);
    }

    // solhint-disable-next-line private-vars-leading-underscore
    function afterDeposit(uint256 assets, uint256 shares) internal override {
        shares;
        supplied += assets;
        _calculateIntrestRates(assets, 0);
    }

    /// Interest rates
    function _calculateIntrestRates(uint256 liquidityAdded, uint256 liquidityTaken) private {
        interestRates = interestRateModel.calculateInterestRates(
            liquidityAdded,
            liquidityTaken
        );
    }
}
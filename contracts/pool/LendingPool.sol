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
import { IInterestRateStrategy, InterestRates } from "./IInterestRateStrategy.sol";
import { SimpleInterestRateStrategy } from "./SimpleInterestRateStrategy.sol";
import { IPriceFeed } from "../oracle/IPriceFeed.sol";

/// @title LendingPool
/// @notice Implements supply and borrow functionality.
/// @dev Implements ERC4626 interface.
contract LendingPool is ERC4626, ReentrancyGuard {

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
    event CollateralAdded(address indexed token, address indexed account, TokenType ofType, uint256 amount);
    event CollateralRemoved(address indexed token, address indexed account, TokenType ofType, uint256 amount);
    event AssetBorrowed(address indexed account, uint256 amount, uint256 debtMinted);
    event AssetRepaid(address indexed account, uint256 amount, uint256 debtBurned);

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

    uint256 public constant MAX_UTILIZATION = 0.98e18;

    /// state vars
    uint256 public supplied;
    uint256 public supplyRate;
    uint256 public borrowRate;

    string public characterization;

    /// Debt and interest
    DebtToken public immutable debtToken;
    IPriceFeed public immutable priceFeed;
    InterestRates public interestRates;
    IInterestRateStrategy public interestRateStrategy;

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

    ///////////////////////////////////////////////////////////////////////////
    ///             initialization
    ///////////////////////////////////////////////////////////////////////////
    constructor(string memory _name, ERC20 _asset, address _priceFeed, CollateralInfo[] memory _collateralTokens) 
    ERC4626(
        _asset,
        string(abi.encodePacked("CHEDDA Token ", _asset.name())), 
        string(abi.encodePacked("ch", _asset.symbol()))) {
        // TODO: set interest rates strategy externally
        interestRateStrategy = new SimpleInterestRateStrategy(
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
    /// @dev Explain to a developer any extra details
    /// @param amount The amount to supply
    /// @param receiver The account to mint share tokens to
    /// @param useAsCollateral Whethe this deposit should be marked as collateral
    /// @return shares The amount of shares minted.
    function supply(uint256 amount, address receiver, bool useAsCollateral) external nonReentrant() returns (uint256) {
        uint256 shares = deposit(amount, receiver);
        if (useAsCollateral) {
            _addCollateral(address(asset), amount);
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

    /// @notice Takes out a loan
    /// @dev The max amount a user can borrow must be less than the value of their collateral weighted
    /// against the loan to value ratio of that colalteral.
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
    /// Emits CollateralAdded(address token, address account, uint tokenType, uint amount).
    /// @param token The token to deposit as collateral.
    /// @param amount The amount of token to deposit.
    function addCollateral(address token, uint256 amount) external nonReentrant() {
        _addCollateral(token, amount);
    }

    function _addCollateral(address token, uint256 amount) private {
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
        
        ERC20(token).safeTransferFrom(account, address(this), amount);
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

    /// @notice Removes ERC20 collateral from pool
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
                uint256 collateralValue = _getTokenCollateralValue(token, amount);
                if (collateralValue > 0) {
                    totalValue += collateralValue;
                }
            }
        }

        return totalValue;
    }

    /// @dev The amount of collateral an account has deposited
    /// TODO: remove. Renamed from `accountCollateralCount`.
    function accountCollateralAmount(address account, address collateral) public view returns (uint256) {
        return accountCollateralDeposited[account][collateral].amount;
    }

    /// @dev Returns the amount of debt owed by a given account.
    /// TODO: remove. Renamed from `accountPendingAmount`
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
    /// health > 1 means the account is solvent.
    /// health <1.0 but != 0 means account is insolvent
    /// health == 0 means account has no debt and is also solvent.
    /// @dev Explain to a developer any extra details
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

    /// @dev returns the market value for a given token amount
    function _getTokenMarketValue(address token, uint256 amount) internal view returns (uint256) {
        int256 price = priceFeed.readPrice(token, 0);
        // if (price < 0) {
        //     revert CheddaPool_InvalidPrice(price, token);
        // }
        return price.toUint256() * amount;
    }

    function _checkAccountHealth(address account) internal view {
        uint256 health = accountHealth(account);
        if (health < 1.0e18) { // 0 health means no debt
            revert CheddaPool_AccountInsolvent(account, health);
        }
    }

    /// To validate borrow
    /// 1. Check that funds are available.
    function _validateBorrow(address, uint256 amount) internal view {
        uint256 available = asset.balanceOf(address(this));
        if (available <= amount) {
            revert CheddaPool_InsufficientAssetBalance(available, amount);
        }
    }

    function _getTokenCollateralValue(address token, uint256 amount) internal view returns (uint256) {
        int256 price = priceFeed.readPrice(token, 0);
        // if (price < 0) {
        //     revert CheddaPool_InvalidPrice(price, token);
        // }
        return (ud(price.toUint256()).mul(ud(amount))).mul(ud(collateralFactor[token])).unwrap();
    }

    /// ERC4626 overrides

    function totalAssets() public override view returns (uint256) {
        return supplied;
    }

    /// Interest rates
    function _calculateIntrestRates(uint256 liquidityAdded, uint256 liquidityTaken) internal {
        interestRates = interestRateStrategy.calculateInterestRates(
            liquidityAdded,
            liquidityTaken
        );
    }
}
